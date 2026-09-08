import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentsService } from '../payments/payments.service';

@Injectable()
export class TransactionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly paymentsService: PaymentsService,
  ) {}

  async getTransactionById(id: string, currentUser: any) {
    return this.paymentsService.getTransactionById(id, currentUser);
  }

  async findAll() {
    return this.prisma.transaction.findMany({
      include: {
        user: { select: { id: true, name: true, email: true } },
        ekub: { select: { id: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
