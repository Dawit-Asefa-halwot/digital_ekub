import { Controller, Get, UseGuards } from '@nestjs/common';
import { RemindersService } from './reminders.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('reminders')
@UseGuards(JwtAuthGuard)
export class RemindersController {
  constructor(private readonly remindersService: RemindersService) {}

  /**
   * Get authenticated user's contribution reminders
   * GET /api/v1/reminders/me
   */
  @Get('me')
  async getUserReminders(@CurrentUser('id') userId: string) {
    return this.remindersService.getUserReminders(userId);
  }
}
