-- Digital Ekub Initial PostgreSQL 18 Migration Script
-- Creates all tables, enums, indexes, and unique constraints.

-- CreateEnums
CREATE TYPE "UserRole" AS ENUM ('MEMBER', 'ADMIN');
CREATE TYPE "EkubCategory" AS ENUM ('POPULAR', 'GROUP', 'CORPORATE', 'IN_KIND');
CREATE TYPE "EkubType" AS ENUM ('CASH', 'IN_KIND');
CREATE TYPE "EkubStatus" AS ENUM ('ACTIVE', 'COMPLETED', 'CLOSED');
CREATE TYPE "Frequency" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY');
CREATE TYPE "PaymentStatus" AS ENUM ('PAID', 'PENDING');
CREATE TYPE "PaymentMethod" AS ENUM ('TELEBIRR', 'CBE_BIRR', 'BANK_TRANSFER');
CREATE TYPE "TransactionType" AS ENUM ('CONTRIBUTION_DEPOSIT', 'POT_PAYOUT_RECEIVED', 'EKUB_CREATION_FEE');
CREATE TYPE "TransactionStatus" AS ENUM ('SUCCESSFUL', 'PENDING', 'FAILED');
CREATE TYPE "RoundStatus" AS ENUM ('SCHEDULED', 'CURRENT', 'COMPLETED');
CREATE TYPE "ReminderStatus" AS ENUM ('UPCOMING', 'DUE', 'OVERDUE', 'PAID');

-- CreateTable users
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'MEMBER',
    "isVerified" BOOLEAN NOT NULL DEFAULT true,
    "notificationsEnabled" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable products
CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "imageUrl" TEXT,
    "productValue" DECIMAL(12,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable ekubs
CREATE TABLE "ekubs" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "category" "EkubCategory" NOT NULL DEFAULT 'GROUP',
    "type" "EkubType" NOT NULL DEFAULT 'CASH',
    "contributionAmount" DECIMAL(12,2) NOT NULL,
    "frequency" "Frequency" NOT NULL DEFAULT 'MONTHLY',
    "maxMembers" INTEGER NOT NULL,
    "joinedMembersCount" INTEGER NOT NULL DEFAULT 0,
    "currentRound" INTEGER NOT NULL DEFAULT 1,
    "totalRounds" INTEGER NOT NULL,
    "totalPot" DECIMAL(12,2) NOT NULL,
    "nextRecipient" TEXT,
    "nextDrawDate" TIMESTAMP(3),
    "status" "EkubStatus" NOT NULL DEFAULT 'ACTIVE',
    "productId" TEXT,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ekubs_pkey" PRIMARY KEY ("id")
);

-- CreateTable ekub_members
CREATE TABLE "ekub_members" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "turnNumber" INTEGER NOT NULL,
    "hasReceivedPot" BOOLEAN NOT NULL DEFAULT false,
    "paymentStatus" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "amountContributed" DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ekub_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable rounds
CREATE TABLE "rounds" (
    "id" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "roundNumber" INTEGER NOT NULL,
    "drawDate" TIMESTAMP(3) NOT NULL,
    "status" "RoundStatus" NOT NULL DEFAULT 'SCHEDULED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rounds_pkey" PRIMARY KEY ("id")
);

-- CreateTable contributions
CREATE TABLE "contributions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "roundId" TEXT,
    "roundNumber" INTEGER NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PAID',
    "transactionId" TEXT,
    "paidAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "contributions_pkey" PRIMARY KEY ("id")
);

-- CreateTable transactions
CREATE TABLE "transactions" (
    "id" TEXT NOT NULL,
    "referenceId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "roundId" TEXT,
    "contributionId" TEXT,
    "amount" DECIMAL(12,2) NOT NULL,
    "type" "TransactionType" NOT NULL,
    "paymentMethod" "PaymentMethod" NOT NULL DEFAULT 'TELEBIRR',
    "status" "TransactionStatus" NOT NULL DEFAULT 'SUCCESSFUL',
    "description" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable draw_results
CREATE TABLE "draw_results" (
    "id" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "roundId" TEXT,
    "roundNumber" INTEGER NOT NULL,
    "winnerId" TEXT NOT NULL,
    "winnerName" TEXT NOT NULL,
    "potAmount" DECIMAL(12,2) NOT NULL,
    "productWon" TEXT,
    "drawDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "eligibleMembersCount" INTEGER NOT NULL,
    "isEkubClosedNow" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "draw_results_pkey" PRIMARY KEY ("id")
);

-- CreateTable reminders
CREATE TABLE "reminders" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "roundNumber" INTEGER NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "dueDate" TIMESTAMP(3) NOT NULL,
    "status" "ReminderStatus" NOT NULL DEFAULT 'DUE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reminders_pkey" PRIMARY KEY ("id")
);

-- CreateTable notifications
CREATE TABLE "notifications" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable audit_events
CREATE TABLE "audit_events" (
    "id" TEXT NOT NULL,
    "ekubId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "iconName" TEXT NOT NULL DEFAULT 'history',
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndexes & Unique Constraints
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
CREATE UNIQUE INDEX "users_phone_key" ON "users"("phone");

CREATE UNIQUE INDEX "ekub_members_userId_ekubId_key" ON "ekub_members"("userId", "ekubId");
CREATE UNIQUE INDEX "rounds_ekubId_roundNumber_key" ON "rounds"("ekubId", "roundNumber");
CREATE UNIQUE INDEX "contributions_userId_ekubId_roundNumber_key" ON "contributions"("userId", "ekubId", "roundNumber");
CREATE UNIQUE INDEX "transactions_referenceId_key" ON "transactions"("referenceId");
CREATE UNIQUE INDEX "draw_results_roundId_key" ON "draw_results"("roundId");
CREATE UNIQUE INDEX "draw_results_ekubId_roundNumber_key" ON "draw_results"("ekubId", "roundNumber");

-- AddForeignKeys
ALTER TABLE "ekubs" ADD CONSTRAINT "ekubs_productId_fkey" FOREIGN KEY ("productId") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "ekubs" ADD CONSTRAINT "ekubs_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ekub_members" ADD CONSTRAINT "ekub_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ekub_members" ADD CONSTRAINT "ekub_members_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "rounds" ADD CONSTRAINT "rounds_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "contributions" ADD CONSTRAINT "contributions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "contributions" ADD CONSTRAINT "contributions_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "contributions" ADD CONSTRAINT "contributions_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "rounds"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "transactions" ADD CONSTRAINT "transactions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "draw_results" ADD CONSTRAINT "draw_results_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "draw_results" ADD CONSTRAINT "draw_results_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "rounds"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "draw_results" ADD CONSTRAINT "draw_results_winnerId_fkey" FOREIGN KEY ("winnerId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "reminders" ADD CONSTRAINT "reminders_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "reminders" ADD CONSTRAINT "reminders_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "notifications" ADD CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "audit_events" ADD CONSTRAINT "audit_events_ekubId_fkey" FOREIGN KEY ("ekubId") REFERENCES "ekubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
