import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { PaymentMethod } from '@prisma/client';

export enum SimulateOutcome {
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
}

export class InitiatePaymentDto {
  @IsNotEmpty({ message: 'Contribution ID is required' })
  @IsString()
  contributionId: string;

  @IsNotEmpty({ message: 'Payment method is required' })
  @IsEnum(PaymentMethod, { message: 'Payment method must be TELEBIRR, CBE_BIRR, or BANK_TRANSFER' })
  paymentMethod: PaymentMethod;

  @IsOptional()
  @IsEnum(SimulateOutcome, { message: 'Simulate outcome must be SUCCESS or FAILED' })
  simulateOutcome?: SimulateOutcome;
}
