import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import {
  EkubStatus,
  PaymentStatus,
  TransactionStatus,
  TransactionType,
  UserRole,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { InitiatePaymentDto, SimulateOutcome } from './dto/initiate-payment.dto';

@Injectable()
export class PaymentsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Process a simulated payment for a pending contribution
   */
  async processPayment(userId: string, dto: InitiatePaymentDto) {
    // 1. Fetch contribution
    const contribution = await this.prisma.contribution.findUnique({
      where: { id: dto.contributionId },
      include: {
        ekub: true,
        user: { select: { id: true, name: true, email: true } },
      },
    });

    if (!contribution) {
      throw new NotFoundException(`Contribution record with ID "${dto.contributionId}" not found`);
    }

    // 2. Security Check: User can only pay their own contribution
    if (contribution.userId !== userId) {
      throw new ForbiddenException('You are only authorized to initiate payments for your own contribution');
    }

    // 3. Prevent duplicate payment of already successful contribution
    if (
      contribution.status === PaymentStatus.PAID ||
      contribution.status === PaymentStatus.SUCCESSFUL
    ) {
      throw new ConflictException('This contribution has already been successfully paid');
    }

    // 4. Validate Ekub state
    if (contribution.ekub.status !== EkubStatus.ACTIVE) {
      throw new BadRequestException('Cannot pay contribution for an Ekub group that is closed or completed');
    }

    // 5. Generate unique transaction reference ID (e.g. TXN-TEL-1725838000-8910)
    const methodPrefix = dto.paymentMethod.substring(0, 3);
    const uniqueRefId = `TXN-${methodPrefix}-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    const amount = Number(contribution.amount);
    const outcome = dto.simulateOutcome || SimulateOutcome.SUCCESS;

    // 6. Execute atomic Prisma Transaction
    return this.prisma.$transaction(async (tx) => {
      // Create initial Payment Audit Log
      await tx.auditEvent.create({
        data: {
          ekubId: contribution.ekubId,
          title: 'PAYMENT_INITIATED',
          description: `Payment of ${amount} ETB initiated via ${dto.paymentMethod} for Round #${contribution.roundNumber}`,
          iconName: 'credit_card',
        },
      });

      if (outcome === SimulateOutcome.SUCCESS) {
        // Create Successful Transaction Ledger Record
        const transaction = await tx.transaction.create({
          data: {
            referenceId: uniqueRefId,
            userId,
            ekubId: contribution.ekubId,
            roundId: contribution.roundId,
            contributionId: contribution.id,
            amount: amount,
            type: TransactionType.CONTRIBUTION_DEPOSIT,
            paymentMethod: dto.paymentMethod,
            status: TransactionStatus.SUCCESSFUL,
            description: `Simulated ${dto.paymentMethod} payment for Round #${contribution.roundNumber}`,
          },
        });

        // Update Contribution Status to PAID
        const updatedContribution = await tx.contribution.update({
          where: { id: contribution.id },
          data: {
            status: PaymentStatus.PAID,
            transactionId: transaction.id,
            paidAt: new Date(),
          },
        });

        // Update Member Total Contribution Balance
        await tx.ekubMember.update({
          where: {
            userId_ekubId: { userId, ekubId: contribution.ekubId },
          },
          data: {
            paymentStatus: PaymentStatus.PAID,
            amountContributed: { increment: amount },
          },
        });

        // Create Payment Success Audit Events
        await tx.auditEvent.create({
          data: {
            ekubId: contribution.ekubId,
            title: 'PAYMENT_SUCCESSFUL',
            description: `Payment ${uniqueRefId} of ${amount} ETB completed successfully via ${dto.paymentMethod}`,
            iconName: 'check_circle',
          },
        });

        await tx.auditEvent.create({
          data: {
            ekubId: contribution.ekubId,
            title: 'CONTRIBUTION_PAID',
            description: `${contribution.user.name} paid contribution for Round #${contribution.roundNumber}`,
            iconName: 'payments',
          },
        });

        return {
          message: 'Payment processed successfully',
          outcome: SimulateOutcome.SUCCESS,
          transaction,
          contribution: updatedContribution,
        };
      } else {
        // Create Failed Transaction Record
        const transaction = await tx.transaction.create({
          data: {
            referenceId: uniqueRefId,
            userId,
            ekubId: contribution.ekubId,
            roundId: contribution.roundId,
            contributionId: contribution.id,
            amount: amount,
            type: TransactionType.CONTRIBUTION_DEPOSIT,
            paymentMethod: dto.paymentMethod,
            status: TransactionStatus.FAILED,
            description: `Simulated failed payment via ${dto.paymentMethod}`,
          },
        });

        // Update Contribution Status to FAILED
        const updatedContribution = await tx.contribution.update({
          where: { id: contribution.id },
          data: {
            status: PaymentStatus.FAILED,
          },
        });

        // Audit Event for Failed Payment
        await tx.auditEvent.create({
          data: {
            ekubId: contribution.ekubId,
            title: 'PAYMENT_FAILED',
            description: `Payment ${uniqueRefId} via ${dto.paymentMethod} failed to process`,
            iconName: 'error',
          },
        });

        return {
          message: 'Payment processing failed',
          outcome: SimulateOutcome.FAILED,
          transaction,
          contribution: updatedContribution,
        };
      }
    });
  }

  /**
   * Get authenticated user's payment and transaction history
   */
  async getUserTransactions(userId: string) {
    return this.prisma.transaction.findMany({
      where: { userId },
      include: {
        ekub: {
          select: { id: true, name: true, type: true, frequency: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get single transaction details by ID with authorization checks
   */
  async getTransactionById(transactionId: string, currentUser: any) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
      include: {
        ekub: {
          select: { id: true, name: true, type: true },
        },
        user: {
          select: { id: true, name: true, email: true },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundException(`Transaction record with ID "${transactionId}" not found`);
    }

    // Security Check: Users can only view their own transactions unless ADMIN
    if (transaction.userId !== currentUser.id && currentUser.role !== UserRole.ADMIN) {
      throw new ForbiddenException('You are not authorized to view another user\'s private transaction details');
    }

    return transaction;
  }

  /**
   * Get supported demo payment gateway methods
   */
  async getPaymentMethods() {
    return [
      { id: 'TELEBIRR', name: 'Telebirr', icon: 'telebirr_logo' },
      { id: 'CBE_BIRR', name: 'CBE Birr', icon: 'cbe_birr_logo' },
      { id: 'BANK_TRANSFER', name: 'Bank Transfer', icon: 'bank_icon' },
    ];
  }
}
