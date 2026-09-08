import {
  Controller,
  Get,
  Post,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { DrawsService } from './draws.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller()
export class DrawsController {
  constructor(private readonly drawsService: DrawsService) {}

  /**
   * DEVELOPMENT / ADMIN Internal Draw Endpoint
   * Trigger scheduled draw execution manually for testing & admin operations
   * POST /api/v1/internal/ekubs/:ekubId/rounds/:roundId/draw
   */
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Post('internal/ekubs/:ekubId/rounds/:roundId/draw')
  @HttpCode(HttpStatus.OK)
  async triggerInternalDraw(
    @Param('ekubId') ekubId: string,
    @Param('roundId') roundId: string,
  ) {
    return this.drawsService.executeDraw(ekubId, roundId);
  }

  /**
   * Get all draw results for an Ekub group
   * GET /api/v1/ekubs/:id/draw-results
   */
  @Get('ekubs/:id/draw-results')
  async getEkubDrawResults(@Param('id') ekubId: string) {
    return this.drawsService.getEkubDrawResults(ekubId);
  }

  /**
   * Get draw result for a specific round
   * GET /api/v1/ekubs/:id/rounds/:roundId/draw-result
   */
  @Get('ekubs/:id/rounds/:roundId/draw-result')
  async getRoundDrawResult(
    @Param('id') ekubId: string,
    @Param('roundId') roundId: string,
  ) {
    return this.drawsService.getRoundDrawResult(ekubId, roundId);
  }
}
