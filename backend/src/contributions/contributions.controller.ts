import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ContributionsService } from './contributions.service';
import { CreateContributionDto } from './dto/create-contribution.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller()
@UseGuards(JwtAuthGuard)
export class ContributionsController {
  constructor(private readonly contributionsService: ContributionsService) {}

  /**
   * Create a contribution deposit for the current Ekub round
   * POST /api/v1/ekubs/:id/contributions
   */
  @Post('ekubs/:id/contributions')
  @HttpCode(HttpStatus.CREATED)
  async createContribution(
    @CurrentUser('id') userId: string,
    @Param('id') ekubId: string,
    @Body() dto: CreateContributionDto,
  ) {
    return this.contributionsService.createContribution(userId, ekubId, dto);
  }

  /**
   * List contribution history for an Ekub group
   * GET /api/v1/ekubs/:id/contributions
   */
  @Get('ekubs/:id/contributions')
  async getEkubContributions(@Param('id') ekubId: string) {
    return this.contributionsService.getEkubContributions(ekubId);
  }

  /**
   * Get current authenticated user's contributions across all Ekubs
   * GET /api/v1/contributions/me
   */
  @Get('contributions/me')
  async getUserContributions(@CurrentUser('id') userId: string) {
    return this.contributionsService.getUserContributions(userId);
  }

  /**
   * Get details of a single contribution
   * GET /api/v1/contributions/:id
   */
  @Get('contributions/:id')
  async getContributionById(@Param('id') id: string) {
    return this.contributionsService.getContributionById(id);
  }
}
