import { IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateContributionDto {
  @IsOptional()
  @IsNumber({}, { message: 'Amount must be a number' })
  @Min(1, { message: 'Contribution amount must be at least 1' })
  amount?: number;

  @IsOptional()
  @IsString()
  roundId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  roundNumber?: number;
}
