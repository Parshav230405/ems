import { PrismaClient, Role } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Ensuring Base Platform and Default School Exist (Preserving All Data) ---');

  // Client 1: Platform Administration Tenant
  await prisma.client.upsert({
    where: { id: 1 },
    update: {},
    create: {
      id: 1,
      name: 'Platform Admin',
      slug: 'platform',
      status: 'active',
      adminEmail: 'superadmin@auraems.com',
    },
  });

  // Client 2: Default Institution Tenant
  await prisma.client.upsert({
    where: { id: 2 },
    update: {},
    create: {
      id: 2,
      name: 'Bright Future Public School',
      slug: 'bright-future',
      status: 'active',
      adminEmail: 'admin@auraems.com',
    },
  });

  console.log('--- Ensuring Administrator Accounts Exist ---');
  const superPassword = await bcrypt.hash('SuperAdmin@123', 10);
  const adminPassword = await bcrypt.hash('Admin@123', 10);

  // Super Admin
  await prisma.user.upsert({
    where: { email: 'superadmin@auraems.com' },
    update: {},
    create: {
      clientId: 1,
      name: 'Platform Super Admin',
      email: 'superadmin@auraems.com',
      passwordHash: superPassword,
      role: Role.SUPERADMIN,
    },
  });

  // School Admin (Client 2)
  await prisma.user.upsert({
    where: { email: 'admin@auraems.com' },
    update: {},
    create: {
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
    const existing = await prisma.setting.findFirst({
      where: { clientId: 2, key: s.key },
    });
    if (!existing) {
      await prisma.setting.create({ data: s });
    }
  }

  // Client 3: KA School (upsert)
  const client3 = await prisma.client.upsert({
    where: { slug: 'ka-school' },
    update: {},
    create: {
      name: 'KA Academy',
      slug: 'ka-school',
      status: 'active',
      adminEmail: 'ka@gmail.com',
    },
  });

  await prisma.user.upsert({
    where: { email: 'ka@gmail.com' },
    update: {},
    create: {
      clientId: client3.id,
      name: 'KA Administrator',
      email: 'ka@gmail.com',
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  // Client 4: DP School (upsert)
  const client4 = await prisma.client.upsert({
    where: { slug: 'dp-school' },
    update: {},
    create: {
      name: 'DP Academy',
      slug: 'dp-school',
      status: 'active',
      adminEmail: 'dp@gmail.com',
    },
  });

  await prisma.user.upsert({
    where: { email: 'dp@gmail.com' },
    update: {},
    create: {
      clientId: client4.id,
      name: 'DP Administrator',
      email: 'dp@gmail.com',
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  // Ensure starter classes for KA & DP
  for (const c of [client3, client4]) {
    const classCount = await prisma.class.count({ where: { clientId: c.id } });
    if (classCount === 0) {
      await prisma.class.createMany({
        data: [
          { clientId: c.id, name: '10', division: 'A', academicYear: '2025-2026' },
          { clientId: c.id, name: '9', division: 'A', academicYear: '2025-2026' },
          { clientId: c.id, name: '8', division: 'A', academicYear: '2025-2026' },
        ],
      });
    }
  }

  // Sync Postgres ID sequence for clients table so newly onboarded schools start after highest id
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
