import { PrismaClient, Role, StudentStatus, AttendanceStatus, PaymentMode } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Cleaning Existing Database Data ---');
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

  console.log('--- Seeding Multi-Tenant Clients ---');
  // Client 1: Reserved Platform Admin
  await prisma.client.create({
    data: {
      id: 1,
      name: 'Platform Admin',
      slug: 'platform',
      status: 'active',
      adminEmail: 'superadmin@auraems.com',
    },
  });

  // Client 2: Bright Future Public School
  await prisma.client.create({
    data: {
      id: 2,
      name: 'Bright Future Public School',
      slug: 'bright-future',
      status: 'active',
      adminEmail: 'admin@auraems.com',
    },
  });

  // Client 3: Indus International Academy
  await prisma.client.create({
    data: {
      id: 3,
      name: 'Indus International Academy',
      slug: 'indus-academy',
      status: 'active',
      adminEmail: 'indus.admin@auraems.com',
    },
  });

  // Client 4: Suspended Academy (for testing suspension blocks)
  await prisma.client.create({
    data: {
      id: 4,
      name: 'Apex Modern Academy (Suspended)',
      slug: 'apex-suspended',
      status: 'suspended',
      adminEmail: 'suspended.admin@auraems.com',
    },
  });

  console.log('--- Seeding Platform Superadmin & Client Users ---');
  const superPassword = await bcrypt.hash('SuperAdmin@123', 10);
  const adminPassword = await bcrypt.hash('Admin@123', 10);
  const staffPassword = await bcrypt.hash('Staff@123', 10);

  // Superadmin (Client 1)
  await prisma.user.create({
    data: {
      clientId: 1,
      name: 'Platform Super Admin',
      email: 'superadmin@auraems.com',
      passwordHash: superPassword,
      role: Role.SUPERADMIN,
    },
  });

  // Client 2 Admin & Staff
  const admin2 = await prisma.user.create({
    data: {
      clientId: 2,
      name: 'Admin User',
      email: 'admin@auraems.com',
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  await prisma.user.create({
    data: {
      clientId: 2,
      name: 'Priya Sharma (Staff)',
      email: 'staff@auraems.com',
      passwordHash: staffPassword,
      role: Role.STAFF,
    },
  });

  // Client 3 Admin
  await prisma.user.create({
    data: {
      clientId: 3,
      name: 'Indus Admin',
      email: 'indus.admin@auraems.com',
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  // Client 4 Admin (Suspended)
  await prisma.user.create({
    data: {
      clientId: 4,
      name: 'Suspended Admin',
      email: 'suspended.admin@auraems.com',
      passwordHash: adminPassword,
      role: Role.ADMIN,
    },
  });

  console.log('--- Seeding Settings for Client 2 ---');
  const settingsData2 = [
    { clientId: 2, key: 'school_name', value: 'Bright Future Public School' },
    { clientId: 2, key: 'school_tagline', value: 'Smart Management for a Brighter Future' },
    { clientId: 2, key: 'school_address', value: '120 Education Road, Ahmedabad, Gujarat - 382115' },
    { clientId: 2, key: 'school_phone', value: '+91 98765 43210' },
    { clientId: 2, key: 'school_email', value: 'info@brightfuture.edu.in' },
    { clientId: 2, key: 'academic_year', value: '2025-2026' },
    { clientId: 2, key: 'principal_name', value: 'Dr. S. K. Mukherjee' },
  ];
  for (const s of settingsData2) {
    await prisma.setting.create({ data: s });
  }

  console.log('--- Seeding Classes for Client 2 ---');
  const class10A = await prisma.class.create({
    data: { clientId: 2, name: '10', division: 'A', academicYear: '2025-2026' },
  });
  const class9B = await prisma.class.create({
    data: { clientId: 2, name: '9', division: 'B', academicYear: '2025-2026' },
  });
  const class8C = await prisma.class.create({
    data: { clientId: 2, name: '8', division: 'C', academicYear: '2025-2026' },
  });

  console.log('--- Seeding Teachers for Client 2 ---');
  const teachers = await Promise.all([
    prisma.teacher.create({
      data: {
        clientId: 2,
        name: 'Ms. Neha Sharma',
        email: 'neha.sharma@auraems.com',
        contact: '9876543210',
        qualification: 'M.Sc. B.Ed.',
        status: 'Active',
      },
    }),
    prisma.teacher.create({
      data: {
        clientId: 2,
        name: 'Mr. Rajesh Patel',
        email: 'rajesh.patel@auraems.com',
        contact: '9876543211',
        qualification: 'M.Sc. B.Ed.',
        status: 'Active',
      },
    }),
    prisma.teacher.create({
      data: {
        clientId: 2,
        name: 'Ms. Pooja Singh',
        email: 'pooja.singh@auraems.com',
        contact: '9876543212',
        qualification: 'M.A. B.Ed.',
        status: 'Active',
      },
    }),
    prisma.teacher.create({
      data: {
        clientId: 2,
        name: 'Mr. Vikram Desai',
        email: 'vikram.desai@auraems.com',
        contact: '9876543213',
        qualification: 'M.A. B.Ed.',
        status: 'Active',
      },
    }),
    prisma.teacher.create({
      data: {
        clientId: 2,
        name: 'Ms. Ritu Shah',
        email: 'ritu.shah@auraems.com',
        contact: '9876543214',
        qualification: 'M.Tech',
        status: 'Active',
      },
    }),
  ]);

  console.log('--- Seeding Subjects for Client 2 ---');
  const subjects10A = await Promise.all([
    prisma.subject.create({
      data: { clientId: 2, name: 'Mathematics', code: 'MATH10', classId: class10A.id, teacherId: teachers[0].id },
    }),
    prisma.subject.create({
      data: { clientId: 2, name: 'Science', code: 'SCI10', classId: class10A.id, teacherId: teachers[1].id },
    }),
    prisma.subject.create({
      data: { clientId: 2, name: 'English', code: 'ENG10', classId: class10A.id, teacherId: teachers[2].id },
    }),
    prisma.subject.create({
      data: { clientId: 2, name: 'Social Science', code: 'SST10', classId: class10A.id, teacherId: teachers[3].id },
    }),
    prisma.subject.create({
      data: { clientId: 2, name: 'Computer Science', code: 'CS10', classId: class10A.id, teacherId: teachers[4].id },
    }),
  ]);

  for (const c of [class9B, class8C]) {
    await Promise.all([
      prisma.subject.create({ data: { clientId: 2, name: 'Mathematics', code: `MATH${c.name}`, classId: c.id, teacherId: teachers[0].id } }),
      prisma.subject.create({ data: { clientId: 2, name: 'Science', code: `SCI${c.name}`, classId: c.id, teacherId: teachers[1].id } }),
      prisma.subject.create({ data: { clientId: 2, name: 'English', code: `ENG${c.name}`, classId: c.id, teacherId: teachers[2].id } }),
    ]);
  }

  console.log('--- Seeding Timetable for Client 2 ---');
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
  const periods = [
    { p: 1, start: '08:00', end: '08:45' },
    { p: 2, start: '08:45', end: '09:30' },
    { p: 3, start: '09:50', end: '10:35' },
    { p: 4, start: '10:35', end: '11:20' },
    { p: 5, start: '11:20', end: '12:05' },
  ];

  for (const d of days) {
    for (let i = 0; i < 5; i++) {
      const sub = subjects10A[(i + days.indexOf(d)) % subjects10A.length];
      await prisma.timetable.create({
        data: {
          clientId: 2,
          classId: class10A.id,
          dayOfWeek: d,
          period: periods[i].p,
          subjectId: sub.id,
          startTime: periods[i].start,
          endTime: periods[i].end,
        },
      });
    }
  }

  console.log('--- Seeding Students for Client 2 (30 students) ---');
  const studentNames = [
    { name: 'Rahul Patel', gender: 'Male', parent: 'Amit Patel', contact: '9876543210' },
    { name: 'Priya Shah', gender: 'Female', parent: 'Rajesh Shah', contact: '9876543211' },
    { name: 'Amit Kumar', gender: 'Male', parent: 'Sunita Kumar', contact: '9876543212' },
    { name: 'Sneha Verma', gender: 'Female', parent: 'Manoj Verma', contact: '9876543213' },
    { name: 'Rohan Mehta', gender: 'Male', parent: 'Pooja Mehta', contact: '9876543214' },
    { name: 'Diya Patel', gender: 'Female', parent: 'Nilesh Patel', contact: '9876543215' },
    { name: 'Aarav Joshi', gender: 'Male', parent: 'Bhavesh Joshi', contact: '9876543216' },
    { name: 'Ananya Iyer', gender: 'Female', parent: 'Raman Iyer', contact: '9876543217' },
    { name: 'Aditya Dave', gender: 'Male', parent: 'Kirit Dave', contact: '9876543218' },
    { name: 'Tanvi Trivedi', gender: 'Female', parent: 'Hasmukh Trivedi', contact: '9876543219' },
    { name: 'Kavya Nair', gender: 'Female', parent: 'Suresh Nair', contact: '9876543220' },
    { name: 'Yash Sharma', gender: 'Male', parent: 'Dinesh Sharma', contact: '9876543221' },
    { name: 'Isha Desai', gender: 'Female', parent: 'Pradeep Desai', contact: '9876543222' },
    { name: 'Manav Bhatt', gender: 'Male', parent: 'Kamlesh Bhatt', contact: '9876543223' },
    { name: 'Riddhi Soni', gender: 'Female', parent: 'Girish Soni', contact: '9876543224' },
    { name: 'Dev Parekh', gender: 'Male', parent: 'Deepak Parekh', contact: '9876543225' },
    { name: 'Bhoomi Chauhan', gender: 'Female', parent: 'Vikram Chauhan', contact: '9876543226' },
    { name: 'Harsh Vyas', gender: 'Male', parent: 'Pankaj Vyas', contact: '9876543227' },
    { name: 'Meera Rao', gender: 'Female', parent: 'Venkatesh Rao', contact: '9876543228' },
    { name: 'Varun Pillai', gender: 'Male', parent: 'Chandran Pillai', contact: '9876543229' },
    { name: 'Karan Singhal', gender: 'Male', parent: 'Ashok Singhal', contact: '9876543230' },
    { name: 'Palak Gupta', gender: 'Female', parent: 'Sudhir Gupta', contact: '9876543231' },
    { name: 'Kunal Kapoor', gender: 'Male', parent: 'Rakesh Kapoor', contact: '9876543232' },
    { name: 'Nisha Modi', gender: 'Female', parent: 'Bharat Modi', contact: '9876543233' },
    { name: 'Siddharth Jain', gender: 'Male', parent: 'Mahesh Jain', contact: '9876543234' },
    { name: 'Riya Agarwal', gender: 'Female', parent: 'Sanjay Agarwal', contact: '9876543235' },
    { name: 'Parth Shukla', gender: 'Male', parent: 'Gautam Shukla', contact: '9876543236' },
    { name: 'Khushi Panchal', gender: 'Female', parent: 'Pravin Panchal', contact: '9876543237' },
    { name: 'Aryan Pandya', gender: 'Male', parent: 'Jayesh Pandya', contact: '9876543238' },
    { name: 'Jiya Shah', gender: 'Female', parent: 'Chetan Shah', contact: '9876543239' },
  ];

  const createdStudents: any[] = [];
  for (let i = 0; i < studentNames.length; i++) {
    const s = studentNames[i];
    const classId = i < 10 ? class10A.id : i < 20 ? class9B.id : class8C.id;
    const admNumber = `ADM${String(i + 1).padStart(3, '0')}`;
    const student = await prisma.student.create({
      data: {
        clientId: 2,
        admissionNumber: admNumber,
        name: s.name,
        dob: new Date('2010-05-15'),
        gender: s.gender,
        classId,
        parentName: s.parent,
        parentContact: s.contact,
        parentEmail: `${s.name.toLowerCase().replace(' ', '.')}@family.com`,
        admissionDate: new Date('2025-06-01'),
        status: StudentStatus.ACTIVE,
      },
    });
    createdStudents.push(student);
  }

  console.log('--- Seeding Attendance for Client 2 ---');
  const today = new Date();
  for (let d = 29; d >= 0; d--) {
    const recordDate = new Date(today);
    recordDate.setDate(today.getDate() - d);
    if (recordDate.getDay() === 0) continue;

    for (const student of createdStudents) {
      const rand = Math.random();
      const status: AttendanceStatus = rand > 0.08 ? AttendanceStatus.PRESENT : rand > 0.03 ? AttendanceStatus.ABSENT : AttendanceStatus.LEAVE;
      await prisma.attendance.create({
        data: {
          clientId: 2,
          studentId: student.id,
          date: recordDate,
          status,
          markedBy: admin2.id,
        },
      });
    }
  }

  console.log('--- Seeding Fee Structures and Payments for Client 2 ---');
  await prisma.feeStructure.create({
    data: {
      clientId: 2,
      classId: class10A.id,
      academicYear: '2025-2026',
      title: 'Annual Tuition Fee',
      amount: 50000,
      dueDate: new Date('2025-10-15'),
    },
  });
  await prisma.feeStructure.create({
    data: {
      clientId: 2,
      classId: class9B.id,
      academicYear: '2025-2026',
      title: 'Annual Tuition Fee',
      amount: 45000,
      dueDate: new Date('2025-10-15'),
    },
  });
  await prisma.feeStructure.create({
    data: {
      clientId: 2,
      classId: class8C.id,
      academicYear: '2025-2026',
      title: 'Annual Tuition Fee',
      amount: 40000,
      dueDate: new Date('2025-10-15'),
    },
  });

  let receiptCounter = 1001;
  for (let i = 0; i < createdStudents.length; i++) {
    const student = createdStudents[i];
    if (i === 0) {
      await prisma.feePayment.create({
        data: {
          clientId: 2,
          studentId: student.id,
          amountPaid: 15000,
          paymentDate: new Date('2025-06-15'),
          mode: PaymentMode.UPI,
          receiptNo: `REC-${receiptCounter++}`,
          notes: '1st Installment',
          receivedBy: admin2.name,
        },
      });
      await prisma.feePayment.create({
        data: {
          clientId: 2,
          studentId: student.id,
          amountPaid: 20000,
          paymentDate: new Date('2025-08-10'),
          mode: PaymentMode.BANK_TRANSFER,
          receiptNo: `REC-${receiptCounter++}`,
          notes: '2nd Installment',
          receivedBy: admin2.name,
        },
      });
    } else if (i % 2 === 0) {
      await prisma.feePayment.create({
        data: {
          clientId: 2,
          studentId: student.id,
          amountPaid: 25000,
          paymentDate: new Date('2025-07-05'),
          mode: PaymentMode.CASH,
          receiptNo: `REC-${receiptCounter++}`,
          notes: 'Tuition Term 1',
          receivedBy: admin2.name,
        },
      });
    } else if (i % 3 === 0) {
      await prisma.feePayment.create({
        data: {
          clientId: 2,
          studentId: student.id,
          amountPaid: 50000,
          paymentDate: new Date('2025-06-20'),
          mode: PaymentMode.ONLINE,
          receiptNo: `REC-${receiptCounter++}`,
          notes: 'Full Annual Payment',
          receivedBy: admin2.name,
        },
      });
    }
  }

  console.log('--- Seeding Exams and Marks for Client 2 ---');
  const examMath = await prisma.exam.create({
    data: {
      clientId: 2,
      name: 'First Term Examination',
      classId: class10A.id,
      subjectId: subjects10A[0].id,
      date: new Date('2025-09-01'),
      maxMarks: 100,
      passMarks: 35,
    },
  });
  const examSci = await prisma.exam.create({
    data: {
      clientId: 2,
      name: 'First Term Examination',
      classId: class10A.id,
      subjectId: subjects10A[1].id,
      date: new Date('2025-09-02'),
      maxMarks: 100,
      passMarks: 35,
    },
  });
  const examEng = await prisma.exam.create({
    data: {
      clientId: 2,
      name: 'First Term Examination',
      classId: class10A.id,
      subjectId: subjects10A[2].id,
      date: new Date('2025-09-03'),
      maxMarks: 100,
      passMarks: 35,
    },
  });

  const mockupMarks = [
    { m: 85, s: 82, e: 78 },
    { m: 92, s: 90, e: 88 },
    { m: 65, s: 68, e: 72 },
    { m: 95, s: 92, e: 91 },
    { m: 72, s: 75, e: 68 },
    { m: 80, s: 84, e: 82 },
    { m: 60, s: 58, e: 64 },
    { m: 89, s: 91, e: 87 },
    { m: 75, s: 70, e: 72 },
    { m: 84, s: 86, e: 80 },
  ];

  for (let i = 0; i < 10; i++) {
    const student = createdStudents[i];
    const score = mockupMarks[i];
    await prisma.mark.create({
      data: { clientId: 2, examId: examMath.id, studentId: student.id, marksObtained: score.m },
    });
    await prisma.mark.create({
      data: { clientId: 2, examId: examSci.id, studentId: student.id, marksObtained: score.s },
    });
    await prisma.mark.create({
      data: { clientId: 2, examId: examEng.id, studentId: student.id, marksObtained: score.e },
    });
  }

  console.log('--- Seeding Notices for Client 2 ---');
  await prisma.notice.create({
    data: {
      clientId: 2,
      title: 'School will remain closed on 15th September 2025',
      body: 'All academic activities will remain suspended on 15th September 2025 on occasion of National Holiday.',
      postedBy: admin2.id,
      postedDate: new Date('2025-09-09'),
    },
  });
  await prisma.notice.create({
    data: {
      clientId: 2,
      title: 'Inter House Sports Competition on 20th September 2025',
      body: 'Annual sports meet registrations are now open with Physical Education department. All houses must submit participant lists by 16th September.',
      postedBy: admin2.id,
      postedDate: new Date('2025-09-08'),
    },
  });
  await prisma.notice.create({
    data: {
      clientId: 2,
      title: 'Fee payment last date is 30th September 2025',
      body: 'Parents and guardians are requested to clear all pending Term 1 dues before 30th September 2025 to avoid late fee penalties.',
      postedBy: admin2.id,
      postedDate: new Date('2025-09-05'),
    },
  });

  console.log('--- Seeding Client 3 Data (Indus International Academy) ---');
  const indusClass = await prisma.class.create({
    data: {
      clientId: 3,
      name: '10',
      division: 'A',
      academicYear: '2025-2026',
    },
  });

  await prisma.student.create({
    data: {
      clientId: 3,
      admissionNumber: 'ADM001',
      name: 'Dev Patel',
      dob: new Date('2011-02-20'),
      gender: 'Male',
      classId: indusClass.id,
      parentName: 'Samir Patel',
      parentContact: '9988776655',
      parentEmail: 'samir.patel@example.com',
      admissionDate: new Date('2025-06-01'),
      status: StudentStatus.ACTIVE,
    },
  });

  await prisma.setting.create({
    data: {
      clientId: 3,
      key: 'school_name',
      value: 'Indus International Academy',
    },
  });

  // Sync Postgres ID sequence for clients table so new client creations increment properly
  await prisma.$executeRawUnsafe(`SELECT setval(pg_get_serial_sequence('"clients"', 'id'), coalesce((SELECT max(id) FROM "clients"), 1));`);

  console.log('--- Database Seeding Completed Successfully! ---');
  console.log('Accounts ready:');
  console.log('Super Admin: superadmin@auraems.com / SuperAdmin@123 (clientId: 1)');
  console.log('Client 2 Admin: admin@auraems.com / Admin@123 (clientId: 2)');
  console.log('Client 2 Staff: staff@auraems.com / Staff@123 (clientId: 2)');
  console.log('Client 3 Admin: indus.admin@auraems.com / Admin@123 (clientId: 3, Dev Patel ADM001)');
  console.log('Client 4 Admin (Suspended): suspended.admin@auraems.com / Admin@123 (clientId: 4)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
