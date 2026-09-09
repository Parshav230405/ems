import fs from 'fs';
import path from 'path';
import { PrismaClient } from '@prisma/client';

async function restoreDatabase() {
  const targetDbUrl = process.env.TARGET_DATABASE_URL || process.env.DATABASE_URL;
  if (!targetDbUrl) {
    console.error('ERROR: TARGET_DATABASE_URL or DATABASE_URL environment variable is required.');
    process.exit(1);
  }

  console.log(`Connecting to target database: ${targetDbUrl.replace(/:[^:@]+@/, ':****@')}`);
  const prisma = new PrismaClient({
    datasources: { db: { url: targetDbUrl } },
  });

  // Find latest JSON backup
  const backupDir = path.resolve(__dirname, '../../backups');
  if (!fs.existsSync(backupDir)) {
    console.error(`ERROR: Backups directory not found at ${backupDir}`);
    process.exit(1);
  }

  const jsonFiles = fs
    .readdirSync(backupDir)
    .filter((f) => f.endsWith('.json'))
    .sort()
    .reverse();

  if (jsonFiles.length === 0) {
    console.error('ERROR: No JSON backup files found to restore.');
    process.exit(1);
  }

  const latestBackupFile = path.join(backupDir, jsonFiles[0]);
  console.log(`Loading backup data from: ${jsonFiles[0]}`);
  const rawData = fs.readFileSync(latestBackupFile, 'utf-8');
  const backup = JSON.parse(rawData);
  const data = backup.data || backup;

  try {
    await prisma.$connect();
    console.log('Connected to target database successfully!');

    console.log('--- Restoring Data in Dependency Order ---');

    // 1. Clients
    if (data.clients && data.clients.length > 0) {
      console.log(`Restoring ${data.clients.length} clients...`);
      for (const item of data.clients) {
        await prisma.client.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 2. Users
    if (data.users && data.users.length > 0) {
      console.log(`Restoring ${data.users.length} users...`);
      for (const item of data.users) {
        await prisma.user.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 3. Settings
    if (data.settings && data.settings.length > 0) {
      console.log(`Restoring ${data.settings.length} settings...`);
      for (const item of data.settings) {
        await prisma.setting.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 4. Classes
    if (data.classes && data.classes.length > 0) {
      console.log(`Restoring ${data.classes.length} classes...`);
      for (const item of data.classes) {
        await prisma.class.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 5. Teachers
    if (data.teachers && data.teachers.length > 0) {
      console.log(`Restoring ${data.teachers.length} teachers...`);
      for (const item of data.teachers) {
        await prisma.teacher.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 6. Subjects
    if (data.subjects && data.subjects.length > 0) {
      console.log(`Restoring ${data.subjects.length} subjects...`);
      for (const item of data.subjects) {
        await prisma.subject.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 7. Students
    if (data.students && data.students.length > 0) {
      console.log(`Restoring ${data.students.length} students...`);
      for (const item of data.students) {
        const studentData = {
          ...item,
          dob: new Date(item.dob),
          admissionDate: new Date(item.admissionDate),
        };
        await prisma.student.upsert({
          where: { id: item.id },
          update: studentData,
          create: studentData,
        });
      }
    }

    // 8. Attendance
    if (data.attendance && data.attendance.length > 0) {
      console.log(`Restoring ${data.attendance.length} attendance records...`);
      for (const item of data.attendance) {
        const attData = {
          ...item,
          date: new Date(item.date),
        };
        await prisma.attendance.upsert({
          where: { id: item.id },
          update: attData,
          create: attData,
        });
      }
    }

    // 9. Exams
    if (data.exams && data.exams.length > 0) {
      console.log(`Restoring ${data.exams.length} exams...`);
      for (const item of data.exams) {
        const examData = {
          ...item,
          date: new Date(item.date),
        };
        await prisma.exam.upsert({
          where: { id: item.id },
          update: examData,
          create: examData,
        });
      }
    }

    // 10. Marks
    if (data.marks && data.marks.length > 0) {
      console.log(`Restoring ${data.marks.length} marks...`);
      for (const item of data.marks) {
        await prisma.mark.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 11. Fee Structures
    if (data.feeStructure && data.feeStructure.length > 0) {
      console.log(`Restoring ${data.feeStructure.length} fee structures...`);
      for (const item of data.feeStructure) {
        await prisma.feeStructure.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 12. Fee Payments
    if (data.feePayments && data.feePayments.length > 0) {
      console.log(`Restoring ${data.feePayments.length} fee payments...`);
      for (const item of data.feePayments) {
        const paymentData = {
          ...item,
          paymentDate: new Date(item.paymentDate),
        };
        await prisma.feePayment.upsert({
          where: { id: item.id },
          update: paymentData,
          create: paymentData,
        });
      }
    }

    // 13. Timetable
    if (data.timetable && data.timetable.length > 0) {
      console.log(`Restoring ${data.timetable.length} timetables...`);
      for (const item of data.timetable) {
        await prisma.timetable.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 14. Notices
    if (data.notices && data.notices.length > 0) {
      console.log(`Restoring ${data.notices.length} notices...`);
      for (const item of data.notices) {
        await prisma.notice.upsert({
          where: { id: item.id },
          update: item,
          create: item,
        });
      }
    }

    // 15. Certificates
    if (data.certificates && data.certificates.length > 0) {
      console.log(`Restoring ${data.certificates.length} certificates...`);
      for (const item of data.certificates) {
        const certData = {
          ...item,
          issuedDate: new Date(item.issuedDate),
        };
        await prisma.certificate.upsert({
          where: { id: item.id },
          update: certData,
          create: certData,
        });
      }
    }

    console.log('--- Database Restoration Completed Successfully! ---');
  } catch (error) {
    console.error('Restoration error:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

restoreDatabase();
