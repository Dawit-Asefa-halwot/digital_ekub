import { Module } from '@nestjs/common';
import { DrawsController } from './draws.controller';
import { DrawsService } from './draws.service';
import { DrawSchedulerService } from './draw-scheduler.service';

@Module({
  controllers: [DrawsController],
  providers: [DrawsService, DrawSchedulerService],
  exports: [DrawsService],
})
export class DrawsModule {}
