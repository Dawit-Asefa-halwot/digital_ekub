import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { TransactionsService } from './transactions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('transactions')
@UseGuards(JwtAuthGuard)
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  /**
   * Get transaction by ID (Authorized to owner or Admin)
   * GET /api/v1/transactions/:id
   */
  @Get(':id')
  async getTransactionById(
    @Param('id') id: string,
    @CurrentUser() currentUser: any,
  ) {
    return this.transactionsService.getTransactionById(id, currentUser);
  }

  /**
   * Get all transactions (Admin view)
   * GET /api/v1/transactions
   */
  @Get()
  async findAll() {
    return this.transactionsService.findAll();
  }
}
