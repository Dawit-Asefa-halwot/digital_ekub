import { Injectable, NotFoundException } from '@nestjs/common';
import { EkubStatus, PaymentStatus, ReminderStatus, RoundStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class RemindersService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get authenticated user's payment reminders across all Ekubs
   */
  async getUserReminders(userId: string) {
    // Synchronize reminders before returning
    await this.syncUserReminders(userId);

    return this.prisma.reminder.findMany({
      where: { userId },
      include: {
        ekub: {
          select: { id: true, name: true, type: true, frequency: true, contributionAmount: true },
        },
      },
      orderBy: [
        { status: 'asc' },
        { dueDate: 'asc' },
      ],
    });
  }

  /**
   * Synchronize reminders for a specific user based on active Ekub memberships
   */
  async syncUserReminders(userId: string) {
    const memberships = await this.prisma.ekubMember.findMany({
      where: { userId },
      include: {
        ekub: {
          include: {
            rounds: {
              where: { status: { in: [RoundStatus.CURRENT, RoundStatus.SCHEDULED] } },
              orderBy: { roundNumber: 'asc' },
              take: 1,
            },
          },
        },
      },
    });

    const now = new Date();

    for (const member of memberships) {
      const ekub = member.ekub;
      if (ekub.status !== EkubStatus.ACTIVE) continue;

      const currentRound = ekub.rounds[0];
      if (!currentRound) continue;

      // Check if user has paid contribution for this round
      const contribution = await this.prisma.contribution.findUnique({
        where: {
          userId_ekubId_roundNumber: {
            userId,
            ekubId: ekub.id,
            roundNumber: currentRound.roundNumber,
          },
        },
      });

      let status: ReminderStatus = ReminderStatus.DUE;
      if (contribution && (contribution.status === PaymentStatus.PAID || contribution.status === PaymentStatus.SUCCESSFUL)) {
        status = ReminderStatus.PAID;
      } else if (currentRound.drawDate < now) {
        status = ReminderStatus.OVERDUE;
      } else {
        const daysDiff = (currentRound.drawDate.getTime() - now.getTime()) / (1000 * 3600 * 24);
        if (daysDiff > 3) {
          status = ReminderStatus.UPCOMING;
        } else {
          status = ReminderStatus.DUE;
        }
      }

      // Upsert reminder record (All active members INCLUDING past winners receive reminders!)
      const existingReminder = await this.prisma.reminder.findFirst({
        where: {
          userId,
          ekubId: ekub.id,
          roundNumber: currentRound.roundNumber,
        },
      });

      if (existingReminder) {
        await this.prisma.reminder.update({
          where: { id: existingReminder.id },
          data: { status, dueDate: currentRound.drawDate },
        });
      } else {
        await this.prisma.reminder.create({
          data: {
            userId,
            ekubId: ekub.id,
            roundNumber: currentRound.roundNumber,
            amount: ekub.contributionAmount,
            dueDate: currentRound.drawDate,
            status,
          },
        });
      }
    }
  }

  /**
   * Sync all reminders globally (called by Cron scheduler)
   */
  async syncAllReminders() {
    const activeMembers = await this.prisma.ekubMember.findMany({
      where: {
        ekub: { status: EkubStatus.ACTIVE },
      },
      select: { userId: true },
    });

    const userIds = Array.from(new Set(activeMembers.map((m) => m.userId)));
    for (const uid of userIds) {
      await this.syncUserReminders(uid);
    }
  }
}
