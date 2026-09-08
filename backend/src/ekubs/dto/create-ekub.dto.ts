import { IsEnum, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';
import { EkubCategory, EkubType, Frequency } from '@prisma/client';

export class CreateEkubDto {
  @IsNotEmpty({ message: 'Ekub name is required' })
  @IsString()
  name: string;

  @IsNotEmpty({ message: 'Description is required' })
  @IsString()
  description: string;

  @IsNotEmpty({ message: 'Category is required' })
  @IsEnum(EkubCategory, { message: 'Category must be POPULAR, GROUP, CORPORATE, or IN_KIND' })
  category: EkubCategory;

  @IsNotEmpty({ message: 'Type is required' })
  @IsEnum(EkubType, { message: 'Type must be CASH or IN_KIND' })
  type: EkubType;

  @IsNotEmpty({ message: 'Contribution amount is required' })
  @IsNumber({}, { message: 'Contribution amount must be a number' })
  @Min(1, { message: 'Contribution amount must be at least 1' })
  contributionAmount: number;

  @IsNotEmpty({ message: 'Frequency is required' })
  @IsEnum(Frequency, { message: 'Frequency must be DAILY, WEEKLY, or MONTHLY' })
  frequency: Frequency;

  @IsNotEmpty({ message: 'Maximum member limit is required' })
  @IsInt()
  @Min(2, { message: 'Maximum members must be at least 2' })
  maxMembers: number;

  @IsNotEmpty({ message: 'Total rounds count is required' })
  @IsInt()
  @Min(1, { message: 'Total rounds must be at least 1' })
  totalRounds: number;

  // In-Kind Product optional fields
  @IsOptional()
  @IsString()
  productName?: string;

  @IsOptional()
  @IsString()
  productDescription?: string;

  @IsOptional()
  @IsNumber()
  productValue?: number;

  @IsOptional()
  @IsString()
  productImageUrl?: string;
}
