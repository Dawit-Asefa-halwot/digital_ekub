import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DrawsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.drawResult.findMany({
      include: {
        winner: {
          select: { id: true, name: true },
        },
        ekub: {
          select: { id: true, name: true },
        },
      },
    });
  }
}
