import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  /**
   * Initiate a simulated payment for a pending contribution
   * POST /api/v1/payments
   */
  @UseGuards(JwtAuthGuard)
  @Post()
  @HttpCode(HttpStatus.OK)
  async processPayment(
    @CurrentUser('id') userId: string,
    @Body() dto: InitiatePaymentDto,
  ) {
    return this.paymentsService.processPayment(userId, dto);
  }

  /**
   * Get authenticated user's payment transaction history
   * GET /api/v1/payments/me
   */
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getUserTransactions(@CurrentUser('id') userId: string) {
    return this.paymentsService.getUserTransactions(userId);
  }

  /**
   * Get supported demo payment methods
   * GET /api/v1/payments/methods
   */
  @Get('methods')
  async getPaymentMethods() {
    return this.paymentsService.getPaymentMethods();
  }
}
