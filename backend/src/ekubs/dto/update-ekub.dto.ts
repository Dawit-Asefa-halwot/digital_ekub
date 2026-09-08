import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
import { EkubStatus } from '@prisma/client';

export class UpdateEkubDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(EkubStatus, { message: 'Status must be ACTIVE, COMPLETED, or CLOSED' })
  status?: EkubStatus;

  @IsOptional()
  @IsString()
  nextRecipient?: string;

  @IsOptional()
  @IsDateString()
  nextDrawDate?: string;
}
