const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Digital Ekub Database Seeding...');

  const bcrypt = require('bcryptjs');
  const defaultHash = await bcrypt.hash('Password123!', 10);

  // 1. Seed Users
  const adminUser = await prisma.user.upsert({
    where: { email: 'dawit@ekub.et' },
    update: { passwordHash: defaultHash },
    create: {
      id: 'usr_admin_01',
      name: 'Dawit Asefa',
      email: 'dawit@ekub.et',
      phone: '0911234567',
      passwordHash: defaultHash,
      role: 'ADMIN',
      isVerified: true,
      notificationsEnabled: true,
    },
  });

  const memberUser = await prisma.user.upsert({
    where: { email: 'abebe@ekub.et' },
    update: { passwordHash: defaultHash },
    create: {
      id: 'usr_member_02',
      name: 'Abebe Tadesse',
      email: 'abebe@ekub.et',
      phone: '0922345678',
      passwordHash: defaultHash,
      role: 'MEMBER',
      isVerified: true,
      notificationsEnabled: true,
    },
  });

  console.log('✅ Users seeded:', adminUser.name, memberUser.name);

  // 2. Seed In-Kind Featured Product
  const tvProduct = await prisma.product.upsert({
    where: { id: 'prod_tv_01' },
    update: {},
    create: {
      id: 'prod_tv_01',
      name: 'Samsung 55" 4K Smart TV',
      description: 'Crystal UHD 4K Resolution, HDR10+, Smart Hub with Tizen OS & AirPlay support.',
      productValue: 15000,
      imageUrl: 'assets/products/samsung_tv.png',
    },
  });

  console.log('✅ Product seeded:', tvProduct.name);

  // 3. Seed Cash Ekub
  const familyEkub = await prisma.ekub.upsert({
    where: { id: 'ekub_01' },
    update: {},
    create: {
      id: 'ekub_01',
      name: 'Family & Friends Ekub',
      description: 'Weekly rotating savings group among close family members and trusted friends.',
      category: 'POPULAR',
      type: 'CASH',
      contributionAmount: 5000,
      frequency: 'WEEKLY',
      maxMembers: 12,
      joinedMembersCount: 12,
      currentRound: 4,
      totalRounds: 12,
      totalPot: 60000,
      nextRecipient: 'Abebe Tadesse',
      nextDrawDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000),
      status: 'ACTIVE',
      createdById: adminUser.id,
    },
  });

  // 4. Seed In-Kind Ekub
  const tvEkub = await prisma.ekub.upsert({
    where: { id: 'ekub_ik_01' },
    update: {},
    create: {
      id: 'ekub_ik_01',
      name: 'Samsung 55" Smart TV Ekub',
      description: 'Get your desired 4K UHD TV through an affordable rotating contribution plan.',
      category: 'IN_KIND',
      type: 'IN_KIND',
      productId: tvProduct.id,
      contributionAmount: 1500,
      frequency: 'MONTHLY',
      maxMembers: 10,
      joinedMembersCount: 7,
      currentRound: 1,
      totalRounds: 10,
      totalPot: 15000,
      nextRecipient: 'First Draw Recipient',
      nextDrawDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000),
      status: 'ACTIVE',
      createdById: adminUser.id,
    },
  });

  console.log('✅ Ekubs seeded:', familyEkub.name, tvEkub.name);

  console.log('🎉 Database seeding complete!');
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error('❌ Seeding error:', e);
    await prisma.$disconnect();
    process.exit(1);
  });
