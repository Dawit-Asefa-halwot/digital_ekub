import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { EkubStatus, PaymentStatus, RoundStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateContributionDto } from './dto/create-contribution.dto';

@Injectable()
export class ContributionsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a contribution for the current Ekub round
   */
  async createContribution(userId: string, ekubId: string, dto: CreateContributionDto) {
    // 1. Fetch Ekub group details
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    // 2. Validate Ekub Status
    if (ekub.status !== EkubStatus.ACTIVE) {
      throw new BadRequestException('Cannot contribute to an Ekub group that is closed or completed');
    }

    // 3. Verify user is an active member of this Ekub
    const member = await this.prisma.ekubMember.findUnique({
      where: {
        userId_ekubId: { userId, ekubId },
      },
      include: {
        user: { select: { name: true } },
      },
    });

    if (!member) {
      throw new ForbiddenException('You must be an active member of this Ekub group to make a contribution');
    }

    // Note: Past winners (member.hasReceivedPot === true) are STILL ALLOWED & REQUIRED to contribute!

    // 4. Determine Round
    const targetRoundNumber = dto.roundNumber || ekub.currentRound;
    const round = await this.prisma.round.findFirst({
      where: {
        ekubId: ekubId,
        roundNumber: targetRoundNumber,
      },
    });

    if (!round) {
      throw new NotFoundException(`Round #${targetRoundNumber} for this Ekub does not exist`);
    }

    if (targetRoundNumber > ekub.currentRound) {
      throw new BadRequestException('Cannot contribute to future rounds prior to round schedule');
    }

    if (round.status === RoundStatus.COMPLETED) {
      throw new BadRequestException(`Round #${targetRoundNumber} is already completed`);
    }

    // 5. Server-side validation of contribution amount against Ekub configured amount
    const requiredAmount = Number(ekub.contributionAmount);
    if (dto.amount !== undefined && Number(dto.amount) !== requiredAmount) {
      throw new BadRequestException(`Contribution amount must equal the required amount of ${requiredAmount} ETB`);
    }

    // 6. Check for duplicate contribution for same user + ekub + roundNumber
    const existingContribution = await this.prisma.contribution.findUnique({
      where: {
        userId_ekubId_roundNumber: {
          userId,
          ekubId,
          roundNumber: targetRoundNumber,
        },
      },
    });

    if (existingContribution) {
      throw new ConflictException(`You have already submitted a contribution for Round #${targetRoundNumber}`);
    }

    // 7. Execute Prisma Transaction to create Contribution and Audit Event
    return this.prisma.$transaction(async (tx) => {
      const contribution = await tx.contribution.create({
        data: {
          userId,
          ekubId,
          roundId: round.id,
          roundNumber: targetRoundNumber,
          amount: requiredAmount,
          status: PaymentStatus.PENDING, // Initial status prior to payment processing
        },
        include: {
          user: {
            select: { id: true, name: true, email: true },
          },
          ekub: {
            select: { id: true, name: true, contributionAmount: true },
          },
        },
      });

      // Audit Log Event
      await tx.auditEvent.create({
        data: {
          ekubId,
          title: 'Contribution Initiated',
          description: `${member.user.name} initiated deposit of ${requiredAmount} ETB for Round #${targetRoundNumber}`,
          iconName: 'account_balance_wallet',
        },
      });

      return contribution;
    });
  }

  /**
   * List contribution history for an Ekub group
   */
  async getEkubContributions(ekubId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    return this.prisma.contribution.findMany({
      where: { ekubId },
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true },
        },
        round: {
          select: { id: true, roundNumber: true, status: true, drawDate: true },
        },
      },
      orderBy: [
        { roundNumber: 'desc' },
        { createdAt: 'desc' },
      ],
    });
  }

  /**
   * Get current authenticated user's contributions across all Ekubs
   */
  async getUserContributions(userId: string) {
    return this.prisma.contribution.findMany({
      where: { userId },
      include: {
        ekub: {
          select: { id: true, name: true, type: true, frequency: true },
        },
        round: {
          select: { id: true, roundNumber: true, drawDate: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get details of a single contribution
   */
  async getContributionById(id: string) {
    const contribution = await this.prisma.contribution.findUnique({
      where: { id },
      include: {
        user: {
          select: { id: true, name: true, email: true, phone: true },
        },
        ekub: {
          select: { id: true, name: true, contributionAmount: true },
        },
        round: {
          select: { id: true, roundNumber: true, status: true },
        },
      },
    });

    if (!contribution) {
      throw new NotFoundException(`Contribution record with ID "${id}" not found`);
    }

    return contribution;
  }
}
