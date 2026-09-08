import { Controller, Get } from '@nestjs/common';
import { DrawsService } from './draws.service';

@Controller('draws')
export class DrawsController {
  constructor(private readonly drawsService: DrawsService) {}

  @Get()
  findAll() {
    return this.drawsService.findAll();
  }
}
