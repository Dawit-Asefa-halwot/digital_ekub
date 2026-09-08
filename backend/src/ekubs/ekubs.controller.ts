import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { EkubsService } from './ekubs.service';
import { CreateEkubDto } from './dto/create-ekub.dto';
import { UpdateEkubDto } from './dto/update-ekub.dto';
import { QueryEkubDto } from './dto/query-ekub.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('ekubs')
export class EkubsController {
  constructor(private readonly ekubsService: EkubsService) {}

  /**
   * Create a new Ekub (ADMIN Only)
   * POST /api/v1/ekubs
   */
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createEkub(@CurrentUser('id') adminUserId: string, @Body() createEkubDto: CreateEkubDto) {
    return this.ekubsService.createEkub(adminUserId, createEkubDto);
  }

  /**
   * Discover and filter Ekub groups
   * GET /api/v1/ekubs
   */
  @Get()
  async discoverEkubs(@Query() query: QueryEkubDto) {
    return this.ekubsService.discoverEkubs(query);
  }

  /**
   * Get single Ekub details
   * GET /api/v1/ekubs/:id
   */
  @Get(':id')
  async getEkubDetails(@Param('id') id: string) {
    return this.ekubsService.getEkubDetails(id);
  }

  /**
   * Get members roster for an Ekub
   * GET /api/v1/ekubs/:id/members
   */
  @Get(':id/members')
  async getMembers(@Param('id') id: string) {
    return this.ekubsService.getMembers(id);
  }

  /**
   * Join an Ekub group (Authenticated Users)
   * POST /api/v1/ekubs/:id/join
   */
  @UseGuards(JwtAuthGuard)
  @Post(':id/join')
  @HttpCode(HttpStatus.OK)
  async joinEkub(@CurrentUser('id') userId: string, @Param('id') ekubId: string) {
    return this.ekubsService.joinEkub(userId, ekubId);
  }

  /**
   * Withdraw / Leave an Ekub group (If rules allow)
   * POST /api/v1/ekubs/:id/leave
   */
  @UseGuards(JwtAuthGuard)
  @Post(':id/leave')
  @HttpCode(HttpStatus.OK)
  async leaveEkub(@CurrentUser('id') userId: string, @Param('id') ekubId: string) {
    return this.ekubsService.leaveEkub(userId, ekubId);
  }

  /**
   * Update Ekub settings or status (ADMIN Only)
   * PATCH /api/v1/ekubs/:id
   */
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Patch(':id')
  async updateEkub(@Param('id') id: string, @Body() updateEkubDto: UpdateEkubDto) {
    return this.ekubsService.updateEkub(id, updateEkubDto);
  }

  /**
   * Close or Delete Ekub (ADMIN Only)
   * DELETE /api/v1/ekubs/:id
   */
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Delete(':id')
  async deleteEkub(@Param('id') id: string) {
    return this.ekubsService.deleteEkub(id);
  }
}
