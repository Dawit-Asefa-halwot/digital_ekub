import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import {
  EkubStatus,
  PaymentMethod,
  PaymentStatus,
  RoundStatus,
  TransactionStatus,
  TransactionType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DrawsService {
  private readonly logger = new Logger(DrawsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Execute Lucky Draw for an Ekub Round (Idempotent & Transactional)
   */
  async executeDraw(ekubId: string, roundId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
      include: { product: true },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    if (ekub.status === EkubStatus.CLOSED || ekub.status === EkubStatus.COMPLETED) {
      throw new BadRequestException('Cannot execute draw on an Ekub group that is closed or completed');
    }

    const round = await this.prisma.round.findFirst({
      where: { id: roundId, ekubId },
    });

    if (!round) {
      throw new NotFoundException(`Round record with ID "${roundId}" not found for this Ekub`);
    }

    // 1. IDEMPOTENCY CHECK: If draw result already exists for this round, return existing result
    const existingDrawResult = await this.prisma.drawResult.findUnique({
      where: {
        ekubId_roundNumber: {
          ekubId,
          roundNumber: round.roundNumber,
        },
      },
      include: {
        winner: { select: { id: true, name: true, email: true } },
      },
    });

    if (existingDrawResult) {
      this.logger.warn(`Draw for Ekub "${ekub.name}" Round #${round.roundNumber} was already executed.`);
      return {
        message: 'Draw has already been completed for this round',
        isAlreadyExecuted: true,
        drawResult: existingDrawResult,
      };
    }

    // 2. ELIGIBILITY CHECK: Fetch active members who have NOT won yet
    const eligibleMembers = await this.prisma.ekubMember.findMany({
      where: {
        ekubId,
        hasReceivedPot: false,
      },
      include: {
        user: { select: { id: true, name: true, email: true, phone: true } },
      },
    });

    if (eligibleMembers.length === 0) {
      throw new BadRequestException('No eligible members remaining for lucky draw in this Ekub');
    }

    // 3. FAIR RANDOM SELECTION: Select exactly ONE winner from eligible roster
    const winnerMember = eligibleMembers[Math.floor(Math.random() * eligibleMembers.length)];
    const winnerId = winnerMember.userId;
    const winnerName = winnerMember.user.name;

    // 4. POT CALCULATION: Sum ONLY successful/paid contributions for this round
    const paidContributions = await this.prisma.contribution.findMany({
      where: {
        ekubId,
        roundNumber: round.roundNumber,
        status: PaymentStatus.PAID,
      },
    });

    const potAmount = paidContributions.reduce((sum, c) => sum + Number(c.amount), 0);

    // 5. ATOMIC PRISMA TRANSACTION
    return this.prisma.$transaction(async (tx) => {
      const isEkubFinishedNow = round.roundNumber >= ekub.totalRounds || eligibleMembers.length === 1;
      const refId = `TXN-POT-${round.roundNumber}-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

      // A. Create Payout Ledger Transaction for Winner
      const payoutTxn = await tx.transaction.create({
        data: {
          referenceId: refId,
          userId: winnerId,
          ekubId,
          roundId: round.id,
          amount: potAmount,
          type: TransactionType.POT_PAYOUT_RECEIVED,
          paymentMethod: PaymentMethod.BANK_TRANSFER,
          status: TransactionStatus.SUCCESSFUL,
          description: `Pot payout of ${potAmount} ETB awarded for Round #${round.roundNumber}`,
        },
      });

      // B. Update Winner Membership (hasReceivedPot = true, winner remains ACTIVE member)
      await tx.ekubMember.update({
        where: {
          userId_ekubId: { userId: winnerId, ekubId },
        },
        data: {
          hasReceivedPot: true,
        },
      });

      // C. Mark Round as COMPLETED
      await tx.round.update({
        where: { id: round.id },
        data: {
          status: RoundStatus.COMPLETED,
        },
      });

      // D. Update Ekub Status or Advance Current Round
      if (isEkubFinishedNow) {
        await tx.ekub.update({
          where: { id: ekubId },
          data: {
            status: EkubStatus.COMPLETED,
            nextRecipient: 'Ekub Completed',
          },
        });
      } else {
        await tx.ekub.update({
          where: { id: ekubId },
          data: {
            currentRound: { increment: 1 },
            nextRecipient: 'Pending Next Draw',
          },
        });
      }

      // E. Create Permanent DrawResult Record
      const drawResult = await tx.drawResult.create({
        data: {
          ekubId,
          roundId: round.id,
          roundNumber: round.roundNumber,
          winnerId,
          winnerName,
          potAmount,
          productWon: ekub.type === 'IN_KIND' ? ekub.product?.name || 'Featured Product' : null,
          eligibleMembersCount: eligibleMembers.length,
          isEkubClosedNow: isEkubFinishedNow,
        },
        include: {
          winner: { select: { id: true, name: true, email: true } },
        },
      });

      // F. Create In-App Notifications for All Members
      const allMembers = await tx.ekubMember.findMany({
        where: { ekubId },
        select: { userId: true },
      });

      const notifications = allMembers.map((m) => {
        const isWinner = m.userId === winnerId;
        return {
          userId: m.userId,
          title: isWinner
            ? `🎉 Congratulations! You Won Round #${round.roundNumber}`
            : `📢 Round #${round.roundNumber} Draw Completed`,
          message: isWinner
            ? `You won Round #${round.roundNumber} of ${ekub.name}! Total payout of ${potAmount} ETB has been awarded.`
            : `Round #${round.roundNumber} draw for ${ekub.name} completed. ${winnerName} was selected as the winner.`,
          isRead: false,
        };
      });

      await tx.notification.createMany({
        data: notifications,
      });

      // G. Log Audit Events
      await tx.auditEvent.createMany({
        data: [
          {
            ekubId,
            title: 'DRAW_STARTED',
            description: `Automated draw started for Round #${round.roundNumber}`,
            iconName: 'casino',
          },
          {
            ekubId,
            title: 'WINNER_SELECTED',
            description: `${winnerName} was randomly selected out of ${eligibleMembers.length} eligible members`,
            iconName: 'emoji_events',
          },
          {
            ekubId,
            title: 'POT_CALCULATED',
            description: `Total round pot calculated as ${potAmount} ETB from successful contributions`,
            iconName: 'calculate',
          },
          {
            ekubId,
            title: 'PAYOUT_CREATED',
            description: `Payout transaction ${refId} created for ${winnerName}`,
            iconName: 'account_balance_wallet',
          },
          {
            ekubId,
            title: 'EKUB_ROUND_COMPLETED',
            description: `Round #${round.roundNumber} marked COMPLETED. ${isEkubFinishedNow ? 'Ekub is now COMPLETED.' : 'Next round active.'}`,
            iconName: 'flag',
          },
        ],
      });

      return {
        message: 'Draw completed successfully',
        isAlreadyExecuted: false,
        drawResult,
        payoutTransaction: payoutTxn,
      };
    });
  }

  /**
   * Get all draw results for an Ekub group
   */
  async getEkubDrawResults(ekubId: string) {
    const ekub = await this.prisma.ekub.findUnique({
      where: { id: ekubId },
    });

    if (!ekub) {
      throw new NotFoundException(`Ekub group with ID "${ekubId}" not found`);
    }

    return this.prisma.drawResult.findMany({
      where: { ekubId },
      include: {
        winner: {
          select: { id: true, name: true, email: true },
        },
      },
      orderBy: { roundNumber: 'asc' },
    });
  }

  /**
   * Get draw result for a specific round
   */
  async getRoundDrawResult(ekubId: string, roundId: string) {
    const result = await this.prisma.drawResult.findFirst({
      where: { ekubId, roundId },
      include: {
        winner: {
          select: { id: true, name: true, email: true },
        },
      },
    });

    if (!result) {
      throw new NotFoundException(`No draw result found for round "${roundId}"`);
    }

    return result;
  }
}
