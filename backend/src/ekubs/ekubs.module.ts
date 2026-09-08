import { Module } from '@nestjs/common';
import { EkubsController } from './ekubs.controller';
import { EkubsService } from './ekubs.service';

@Module({
  controllers: [EkubsController],
  providers: [EkubsService],
  exports: [EkubsService],
})
export class EkubsModule {}
