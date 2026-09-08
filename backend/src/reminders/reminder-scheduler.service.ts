import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { RemindersService } from './reminders.service';

@Injectable()
export class ReminderSchedulerService {
  private readonly logger = new Logger(ReminderSchedulerService.name);

  constructor(private readonly remindersService: RemindersService) {}

  /**
   * Automated Background Task: Checks every 60 seconds and updates reminder statuses (UPCOMING, DUE, OVERDUE, PAID).
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async handleScheduledReminders() {
    try {
      this.logger.log('⏰ Reminder Scheduler Task: Synchronizing contribution reminder statuses...');
      await this.remindersService.syncAllReminders();
      this.logger.log('✅ Reminder Scheduler Task: Reminders synchronized successfully.');
    } catch (error) {
      this.logger.error(`❌ Reminder Scheduler Error: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
