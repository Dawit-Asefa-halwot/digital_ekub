import { IsBoolean, IsEnum, IsNumber, IsOptional, IsString } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { EkubCategory, EkubStatus, EkubType, Frequency } from '@prisma/client';

export class QueryEkubDto {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsEnum(EkubCategory)
  category?: EkubCategory;

  @IsOptional()
  @IsEnum(EkubType)
  type?: EkubType;

  @IsOptional()
  @IsEnum(Frequency)
  frequency?: Frequency;

  @IsOptional()
  @IsEnum(EkubStatus)
  status?: EkubStatus;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  minContribution?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  maxContribution?: number;

  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  availableSlotsOnly?: boolean;
}
