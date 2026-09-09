import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Wiping All Dummy Records & Initializing Clean Database ---');
  await prisma.certificate.deleteMany();
  await prisma.feePayment.deleteMany();
  await prisma.feeStructure.deleteMany();
  await prisma.mark.deleteMany();
  await prisma.exam.deleteMany();
  await prisma.attendance.deleteMany();
  await prisma.timetable.deleteMany();
  await prisma.notice.deleteMany();
  await prisma.student.deleteMany();
  await prisma.subject.deleteMany();
  await prisma.teacher.deleteMany();
  await prisma.class.deleteMany();
  await prisma.setting.deleteMany();
  await prisma.user.deleteMany();
  await prisma.client.deleteMany();

  console.log('--- Initializing Clean Tenants ---');
  // Client 1: Platform Administration Tenant
  await prisma.client.create({
    data: {
      id: 1,
      name: 'Platform Admin',
      slug: 'platform',
      status: 'active',
      adminEmail: 'superadmin@auraems.com',
    },
  });

  // Client 2: Fresh Institution Tenant (Clean slate for client)
  await prisma.client.create({
    data: {
      id: 2,
      name: 'Bright Future Public School',
      slug: 'bright-future',
      status: 'active',
      adminEmail: 'admin@auraems.com',
    },
  });

  console.log('--- Provisioning Clean Administrator Accounts ---');
  const superPassword = await bcrypt.hash('SuperAdmin@123', 10);
  const adminPassword = await bcrypt.hash('Admin@123', 10);

  // Super Admin
  await prisma.user.create({
    data: {
      clientId: 1,
      name: 'Platform Super Admin',
      email: 'superadmin@auraems.com',
      passwordHash: superPassword,
      role: Role.SUPERADMIN,
    },
  });

  // School Admin (Client 2)
  await prisma.user.create({
    data: {
      clientId: 2,
      name: 'School Administrator',
      email: 'admin@auraems.com',
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  console.log('--- Initializing Clean Settings for School Tenant ---');
  const defaultSettings = [
    { clientId: 2, key: 'school_name', value: 'Bright Future Public School' },
    { clientId: 2, key: 'school_tagline', value: 'Learn • Grow • Succeed' },
    { clientId: 2, key: 'school_address', value: 'Education Road, Gujarat, India' },
    { clientId: 2, key: 'school_phone', value: '+91 98765 43210' },
    { clientId: 2, key: 'school_email', value: 'admin@auraems.com' },
    { clientId: 2, key: 'academic_year', value: '2025-2026' },
    { clientId: 2, key: 'principal_name', value: 'School Principal' },
  ];

  for (const s of defaultSettings) {
    await prisma.setting.create({ data: s });
  }

  // Sync Postgres ID sequence for clients table so new onboarded schools start from 3
  await prisma.$executeRawUnsafe(
    `SELECT setval(pg_get_serial_sequence('"clients"', 'id'), coalesce((SELECT max(id) FROM "clients"), 1));`
  );

  console.log('======================================================');
  console.log(' Clean Slate Initialization Completed!');
  console.log(' ZERO dummy students, ZERO dummy teachers, ZERO dummy exams.');
  console.log(' Ready for live client usage:');
  console.log(' - Super Admin: superadmin@auraems.com / SuperAdmin@123');
  console.log(' - School Admin: admin@auraems.com / Admin@123');
  console.log('======================================================');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
