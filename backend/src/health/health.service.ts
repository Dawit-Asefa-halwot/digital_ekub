import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService) {}

  async checkHealth() {
    try {
      // Execute a quick count query on Prisma to verify PostgreSQL 18 connection
      const userCount = await this.prisma.user.count();
      const ekubCount = await this.prisma.ekub.count();

      return {
        status: 'ok',
        service: 'Digital Ekub REST API',
        timestamp: new Date().toISOString(),
        database: {
          connected: true,
          provider: 'PostgreSQL 18',
          databaseName: 'digital_ekub',
          metrics: {
            totalUsers: userCount,
            totalEkubs: ekubCount,
          },
        },
      };
    } catch (error) {
      return {
        status: 'error',
        service: 'Digital Ekub REST API',
        timestamp: new Date().toISOString(),
        database: {
          connected: false,
          error: error instanceof Error ? error.message : String(error),
        },
      };
    }
  }
}
