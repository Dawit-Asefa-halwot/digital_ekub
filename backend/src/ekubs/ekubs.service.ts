import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { EkubStatus, EkubType, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateEkubDto } from './dto/create-ekub.dto';
import { UpdateEkubDto } from './dto/update-ekub.dto';
import { QueryEkubDto } from './dto/query-ekub.dto';

@Injectable()
export class EkubsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new Ekub group (Admin only)
   */
  async createEkub(adminUserId: string, dto: CreateEkubDto) {
    const totalPot = dto.contributionAmount * dto.maxMembers;

    return this.prisma.$transaction(async (tx) => {
      let productId: string | undefined;

      // Handle In-Kind product creation
      if (dto.type === EkubType.IN_KIND) {
        if (!dto.productName || !dto.productValue) {
          throw new BadRequestException('In-Kind Ekub requires productName and productValue');
        }

        const product = await tx.product.create({
          data: {
            name: dto.productName,
            description: dto.productDescription || dto.description,
            productValue: dto.productValue,
            imageUrl: dto.productImageUrl || 'assets/products/default_product.png',
          },
        });
        productId = product.id;
      }

      // Create Ekub record
      const ekub = await tx.ekub.create({
        data: {
          name: dto.name,
          description: dto.description,
          category: dto.category,
          type: dto.type,
          contributionAmount: dto.contributionAmount,
          frequency: dto.frequency,
          maxMembers: dto.maxMembers,
          joinedMembersCount: 1, // Admin is turn 1 member
          currentRound: 1,
          totalRounds: dto.totalRounds,
          totalPot: totalPot,
          status: EkubStatus.ACTIVE,
          productId: productId,
          createdById: adminUserId,
        },
      });

      // Add Admin creator as turn 1 member
      await tx.ekubMember.create({
        data: {
          userId: adminUserId,
          ekubId: ekub.id,
          turnNumber: 1,
          hasReceivedPot: false,
          amountContributed: 0,
        },
      });

      // Pre-generate lifecycle Rounds
      const roundData = [];
      const now = new Date();
      for (let i = 1; i <= dto.totalRounds; i++) {
        const drawDate = new Date(now);
        if (dto.frequency === 'DAILY') drawDate.setDate(now.getDate() + i);
        else if (dto.frequency === 'WEEKLY') drawDate.setDate(now.getDate() + i * 7);
        else drawDate.setMonth(now.getMonth() + i);

        roundData.push({
          ekubId: ekub.id,
          roundNumber: i,
          drawDate: drawDate,
          status: i === 1 ? 'CURRENT' : 'SCHEDULED',
        });
      }

      await tx.round.createMany({
        data: roundData as any,
      });

      // Log Audit Event
      await tx.auditEvent.create({
        data: {
          ekubId: ekub.id,
          title: 'Ekub Created',
          description: `Ekub "${ekub.name}" was created by admin.`,
          iconName: 'add_circle',
        },
      });

      return tx.ekub.findUnique({
        where: { id: ekub.id },
        include: { product: true, createdBy: { select: { id: true, name: true, email: true } } },
      });
    });
  }

  /**
   * Discover Ekubs with search and query filters
   */
  async discoverEkubs(query: QueryEkubDto) {
    const whereClause: any = {};

    if (query.search) {
      whereClause.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    if (query.category) whereClause.category = query.category;
    if (query.type) whereClause.type = query.type;
    if (query.frequency) whereClause.frequency = query.frequency;
    if (query.status) whereClause.status = query.status;

    if (query.minContribution !== undefined || query.maxContribution !== undefined) {
      whereClause.contributionAmount = {};
      if (query.minContribution !== undefined) whereClause.contributionAmount.gte = query.minContribution;
      if (query.maxContribution !== undefined) whereClause.contributionAmount.lte = query.maxContribution;
    }

    let ekubs = await this.prisma.ekub.findMany({
      where: whereClause,
      include: {
        product: true,
        createdBy: {
          select: { id: true, name: true, email: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (query.availableSlotsOnly) {
      ekubs = ekubs.filter((e) => e.joinedMembersCount < e.maxMembers);
    }

    return ekubs;
  }

  /**
   * Get single Ekub details
   */
  async getEkubDetails(id: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id },
      include: {
        product: true,
        createdBy: {
          select: { id: true, name: true, email: true, phone: true },
        },
        rounds: {
          orderBy: { roundNumber: 'asc' },
        },
        auditEvents: {
          take: 10,
          orderBy: { timestamp: 'desc' },
        },
      },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${id}" not found`);
    }

    return ekub;
  }

  /**
   * Join an Ekub group
   */
  async joinEkub(userId: string, ekubId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    if (ekub.status !== EkubStatus.ACTIVE) {
      throw new BadRequestException('Cannot join an Ekub group that is closed or completed');
    }

    if (ekub.joinedMembersCount >= ekub.maxMembers) {
      throw new BadRequestException('Ekub has reached its maximum member capacity');
    }

    // Check existing membership at business logic level
    const existingMember = await this.prisma.ekubMember.findUnique({
      where: {
        userId_ekubId: { userId, ekubId },
      },
    });

    if (existingMember) {
      throw new ConflictException('You are already a member of this Ekub group');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { name: true },
    });

    return this.prisma.$transaction(async (tx) => {
      const nextTurnNumber = ekub.joinedMembersCount + 1;

      // 1. Create membership record (enforces unique constraint @@unique([userId, ekubId]))
      const membership = await tx.ekubMember.create({
        data: {
          userId,
          ekubId,
          turnNumber: nextTurnNumber,
          hasReceivedPot: false,
          amountContributed: 0,
        },
      });

      // 2. Increment joined members count
      await tx.ekub.update({
        where: { id: ekubId },
        data: {
          joinedMembersCount: { increment: 1 },
        },
      });

      // 3. Create Audit Log
      await tx.auditEvent.create({
        data: {
          ekubId,
          title: 'Member Joined',
          description: `${user?.name || 'A user'} joined as Member #${nextTurnNumber}`,
          iconName: 'person_add',
        },
      });

      return {
        message: 'Successfully joined Ekub group',
        membership,
      };
    });
  }

  /**
   * Withdraw / Leave an Ekub group (If rules allow prior to round 1 commencement)
   */
  async leaveEkub(userId: string, ekubId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    const member = await this.prisma.ekubMember.findUnique({
      where: { userId_ekubId: { userId, ekubId } },
    });

    if (!member) {
      throw new NotFoundException('You are not a member of this Ekub group');
    }

    // FINANCIAL RULE: Cannot leave after round 1 has started or after receiving pot
    if (ekub.currentRound > 1) {
      throw new BadRequestException('Arbitrary withdrawal is prohibited after round 1 has commenced');
    }

    if (member.hasReceivedPot) {
      throw new BadRequestException('Cannot withdraw after receiving the pot payout');
    }

    if (Number(member.amountContributed) > 0) {
      throw new BadRequestException('Cannot withdraw after making contributions for active rounds');
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { name: true },
    });

    return this.prisma.$transaction(async (tx) => {
      await tx.ekubMember.delete({
        where: { id: member.id },
      });

      await tx.ekub.update({
        where: { id: ekubId },
        data: {
          joinedMembersCount: { decrement: 1 },
        },
      });

      await tx.auditEvent.create({
        data: {
          ekubId,
          title: 'Member Left',
          description: `${user?.name || 'A user'} withdrew from the Ekub before round 1.`,
          iconName: 'person_remove',
        },
      });

      return {
        message: 'Successfully withdrew from Ekub group',
      };
    });
  }

  /**
   * Get members roster for an Ekub
   */
  async getMembers(ekubId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    const members = await this.prisma.ekubMember.findMany({
      where: { ekubId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            isVerified: true,
          },
        },
      },
      orderBy: { turnNumber: 'asc' },
    });

    return members.map((m) => ({
      membershipId: m.id,
      userId: m.user.id,
      displayName: m.user.name,
      email: m.user.email,
      phone: m.user.phone,
      isVerified: m.user.isVerified,
      turnNumber: m.turnNumber,
      hasWon: m.hasReceivedPot,
      wonRound: m.hasReceivedPot ? m.turnNumber : null,
      paymentStatus: m.paymentStatus,
      amountContributed: m.amountContributed,
      joinedAt: m.joinedAt,
    }));
  }

  /**
   * Update Ekub properties or status (Admin only)
   */
  async updateEkub(ekubId: string, dto: UpdateEkubDto) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    const updated = await this.prisma.ekub.update({
      where: { id: ekubId },
      data: {
        name: dto.name,
        description: dto.description,
        status: dto.status,
        nextRecipient: dto.nextRecipient,
        nextDrawDate: dto.nextDrawDate ? new Date(dto.nextDrawDate) : undefined,
      },
      include: { product: true },
    });

    return updated;
  }

  /**
   * Close or Delete Ekub (Admin only)
   */
  async deleteEkub(ekubId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    // Set status to CLOSED
    return this.prisma.ekub.update({
      where: { id: ekubId },
      data: { status: EkubStatus.CLOSED },
    });
  }
}
