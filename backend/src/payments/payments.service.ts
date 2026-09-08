import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  async getMethods() {
    return [
      { id: 'TELEBIRR', name: 'Telebirr' },
      { id: 'CBE_BIRR', name: 'CBE Birr' },
      { id: 'BANK_TRANSFER', name: 'Bank Transfer' },
    ];
  }
}
