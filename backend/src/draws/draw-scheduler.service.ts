import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { RoundStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { DrawsService } from './draws.service';

@Injectable()
export class DrawSchedulerService {
  private readonly logger = new Logger(DrawSchedulerService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly drawsService: DrawsService,
  ) {}

  /**
   * Automated Background Task: Checks every 30 seconds for due rounds and executes the lucky draw.
   */
  @Cron(CronExpression.EVERY_30_SECONDS)
  async handleScheduledDraws() {
    try {
      const now = new Date();
      // Find rounds whose draw date has arrived and status is CURRENT
      const dueRounds = await this.prisma.round.findMany({
        where: {
          drawDate: { lte: now },
          status: RoundStatus.CURRENT,
        },
      });

      if (dueRounds.length === 0) {
        return;
      }

      this.logger.log(`⏰ Scheduled Draw Task: Found ${dueRounds.length} due round(s) ready for automatic lucky draw.`);

      for (const round of dueRounds) {
        try {
          this.logger.log(`🎲 Executing automated draw for Ekub "${round.ekubId}" Round #${round.roundNumber}...`);
          const result = await this.drawsService.executeDraw(round.ekubId, round.id);
          this.logger.log(`✅ Automated draw completed for Round #${round.roundNumber}. Winner: ${result.drawResult.winnerName}, Pot: ${result.drawResult.potAmount} ETB`);
        } catch (error) {
          this.logger.error(
            `❌ Error executing automated draw for Round #${round.roundNumber}: ${error instanceof Error ? error.message : String(error)}`,
          );
        }
      }
    } catch (error) {
      this.logger.error(`❌ Draw Scheduler Task Error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
