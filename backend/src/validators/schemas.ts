import { z } from 'zod';
import { Role, StudentStatus, AttendanceStatus, PaymentMode } from '@prisma/client';

export const loginSchema = z.object({
  email: z.string().email('Invalid email address format'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
});

export const userCreateSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  role: z.nativeEnum(Role).default(Role.STAFF),
});

export const classCreateSchema = z.object({
  name: z.string().min(1, 'Class name is required (e.g. 10)'),
  division: z.string().min(1, 'Division is required (e.g. A)'),
  academicYear: z.string().min(4, 'Academic year is required (e.g. 2025-2026)'),
});

export const teacherCreateSchema = z.object({
  name: z.string().min(2, 'Teacher name is required'),
  email: z.string().email('Invalid teacher email format'),
  contact: z.string().min(10, 'Contact number must be at least 10 digits'),
  qualification: z.string().min(2, 'Qualification is required'),
  status: z.string().default('Active'),
});

export const subjectCreateSchema = z.object({
  name: z.string().min(2, 'Subject name is required'),
  code: z.string().optional(),
  classId: z.string().uuid('Valid Class ID is required'),
  teacherId: z.string().uuid('Valid Teacher ID is required').optional().nullable(),
});

export const studentCreateSchema = z.object({
  name: z.string().min(2, 'Student name is required'),
  admissionNumber: z.string().optional(), // Auto-generated if not provided
  dob: z.string().refine((val) => !isNaN(Date.parse(val)), 'Valid date of birth required'),
  gender: z.string().min(1, 'Gender is required'),
  classId: z.string().uuid('Valid Class ID is required'),
  parentName: z.string().min(2, 'Parent name is required'),
  parentContact: z.string().min(10, 'Parent contact must be at least 10 digits'),
  parentEmail: z.string().email('Invalid parent email').optional().nullable(),
  admissionDate: z.string().optional(),
  status: z.nativeEnum(StudentStatus).default(StudentStatus.ACTIVE),
});

export const studentUpdateSchema = studentCreateSchema.partial();

export const attendanceBatchSchema = z.object({
  date: z.string().refine((val) => !isNaN(Date.parse(val)), 'Valid date is required (YYYY-MM-DD)'),
  classId: z.string().uuid('Valid Class ID is required'),
  records: z.array(
    z.object({
      studentId: z.string().uuid('Valid Student ID is required'),
      status: z.nativeEnum(AttendanceStatus),
    })
  ).min(1, 'At least one attendance record is required'),
});

export const examCreateSchema = z.object({
  name: z.string().min(2, 'Exam name is required (e.g. Term 1 Exam)'),
  classId: z.string().uuid('Valid Class ID is required'),
  subjectId: z.string().uuid('Valid Subject ID is required'),
  date: z.string().refine((val) => !isNaN(Date.parse(val)), 'Valid exam date is required'),
  maxMarks: z.number().int().positive().default(100),
  passMarks: z.number().int().positive().default(35),
});

export const marksBatchSchema = z.object({
  examId: z.string().uuid('Valid Exam ID is required'),
  marks: z.array(
    z.object({
      studentId: z.string().uuid('Valid Student ID is required'),
      marksObtained: z.number().min(0, 'Marks cannot be negative'),
    })
  ).min(1, 'At least one mark entry is required'),
});

export const feeStructureSchema = z.object({
  classId: z.string().uuid('Valid Class ID is required'),
  academicYear: z.string().min(4, 'Academic year is required'),
  title: z.string().min(2, 'Fee title is required'),
  amount: z.number().positive('Fee amount must be positive'),
  dueDate: z.string().refine((val) => !isNaN(Date.parse(val)), 'Valid due date is required'),
});

export const feePaymentSchema = z.object({
  studentId: z.string().uuid('Valid Student ID is required'),
  amountPaid: z.number().positive('Payment amount must be greater than 0'),
  paymentDate: z.string().optional(),
  mode: z.nativeEnum(PaymentMode).default(PaymentMode.CASH),
  receiptNo: z.string().optional(), // Auto-generated if omitted
  notes: z.string().optional().nullable(),
});

export const noticeCreateSchema = z.object({
  title: z.string().min(3, 'Notice title is required'),
  body: z.string().min(5, 'Notice body is required'),
  classId: z.string().uuid().optional().nullable(),
});

export const timetableSchema = z.object({
  classId: z.string().uuid('Valid Class ID is required'),
  dayOfWeek: z.enum(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']),
  period: z.number().int().min(1).max(10),
  subjectId: z.string().uuid('Valid Subject ID is required'),
  startTime: z.string().optional().nullable(),
  endTime: z.string().optional().nullable(),
});

export const certificateGenerateSchema = z.object({
  studentId: z.string().uuid('Valid Student ID is required'),
  type: z.string().default('Achievement'),
  title: z.string().min(3, 'Certificate title is required (e.g. CERTIFICATE OF ACHIEVEMENT)'),
  body: z.string().min(10, 'Custom certificate body text is required'),
  templateId: z.string().default('institutional_letterhead_v1'),
});

export const settingUpdateSchema = z.object({
  school_name: z.string().min(2).optional(),
  school_tagline: z.string().optional(),
  school_address: z.string().optional(),
  school_phone: z.string().optional(),
  school_email: z.string().email().optional(),
  academic_year: z.string().optional(),
  principal_name: z.string().optional(),
});

export const internshipReportGenerateSchema = z.object({
  studentId: z.string().uuid('Valid Student ID is required'),
  projectTitle: z.string().min(3, 'Project title is required'),
  internshipTitle: z.string().default('Full-Stack Web Development'),
  companyName: z.string().min(2, 'Company name is required'),
  companyAddress: z.string().optional().default('B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India'),
  companyGuide: z.string().optional().default('Bhavi Kansara (CEO)'),
  facultyGuide: z.string().optional().default('Internal Faculty Guide'),
  universityName: z.string().optional().default('INDUS UNIVERSITY'),
  instituteName: z.string().optional().default('INSTITUTE OF TECHNOLOGY AND ENGINEERING'),
  departmentName: z.string().optional().default('COMPUTER SCIENCE ENGINEERING'),
  courseCode: z.string().optional().default('CE0318 / CE0523 / CE0726'),
  duration: z.string().optional().default('15 Days / 65+ Hours'),
  abstract: z.string().optional().default(''),
  technologies: z.string().optional().default('Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM, JWT, PDFKit'),
});

