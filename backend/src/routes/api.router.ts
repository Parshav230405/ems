import { Router } from 'express';
import { Role } from '@prisma/client';
import {
  authenticateToken,
  requireRole,
  requireSuperAdmin,
  requireSchoolTenant,
} from '../middleware/auth.middleware';
import { validateBody } from '../middleware/validation.middleware';
import {
  loginSchema,
  userCreateSchema,
  studentCreateSchema,
  studentUpdateSchema,
  teacherCreateSchema,
  classCreateSchema,
  subjectCreateSchema,
  attendanceBatchSchema,
  examCreateSchema,
  marksBatchSchema,
  feeStructureSchema,
  feePaymentSchema,
  certificateGenerateSchema,
  timetableSchema,
  noticeCreateSchema,
  settingUpdateSchema,
  internshipReportGenerateSchema,
} from '../validators/schemas';

import { AuthController } from '../controllers/auth.controller';
import { ClientsController } from '../controllers/clients.controller';
import { DashboardController } from '../controllers/dashboard.controller';
import { StudentsController } from '../controllers/students.controller';
import { TeachersController } from '../controllers/teachers.controller';
import { ClassesController } from '../controllers/classes.controller';
import { SubjectsController } from '../controllers/subjects.controller';
import { AttendanceController } from '../controllers/attendance.controller';
import { ExamsController } from '../controllers/exams.controller';
import { FeesController } from '../controllers/fees.controller';
import { CertificatesController } from '../controllers/certificates.controller';
import { TimetableController } from '../controllers/timetable.controller';
import { NoticesController } from '../controllers/notices.controller';
import { ReportsController } from '../controllers/reports.controller';
import { SettingsController } from '../controllers/settings.controller';

const router = Router();

// --- Health Check ---
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// --- Auth Routes ---
router.post('/auth/login', validateBody(loginSchema), AuthController.login);
router.get('/auth/me', authenticateToken, AuthController.me);
router.post(
  '/auth/users',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  validateBody(userCreateSchema),
  AuthController.createUser
);
router.get(
  '/auth/users',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  AuthController.listUsers
);

// --- Super Admin Client Console Routes (Platform Owner, clientId = 1) ---
router.get('/clients/stats', authenticateToken, requireSuperAdmin, ClientsController.getPlatformStats);
router.get('/clients', authenticateToken, requireSuperAdmin, ClientsController.listClients);
router.get('/clients/:id', authenticateToken, requireSuperAdmin, ClientsController.getClient);
router.post('/clients', authenticateToken, requireSuperAdmin, ClientsController.createClient);
router.patch('/clients/:id/status', authenticateToken, requireSuperAdmin, ClientsController.updateStatus);
router.delete('/clients/:id', authenticateToken, requireSuperAdmin, ClientsController.deleteClient);

// --- Dashboard (School Tenants Only) ---
router.get('/dashboard', authenticateToken, requireSchoolTenant, DashboardController.getSummary);

// --- Student Management ---
router.get('/students', authenticateToken, requireSchoolTenant, StudentsController.listStudents);
router.get('/students/:id', authenticateToken, requireSchoolTenant, StudentsController.getStudentById);
router.post(
  '/students',
  authenticateToken,
  requireSchoolTenant,
  validateBody(studentCreateSchema),
  StudentsController.createStudent
);
router.put(
  '/students/:id',
  authenticateToken,
  requireSchoolTenant,
  validateBody(studentUpdateSchema),
  StudentsController.updateStudent
);
router.delete(
  '/students/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]), // Staff cannot delete students
  StudentsController.deleteStudent
);

// --- Teacher Management ---
router.get('/teachers', authenticateToken, requireSchoolTenant, TeachersController.listTeachers);
router.get('/teachers/:id', authenticateToken, requireSchoolTenant, TeachersController.getTeacherById);
router.post(
  '/teachers',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  validateBody(teacherCreateSchema),
  TeachersController.createTeacher
);
router.put(
  '/teachers/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  TeachersController.updateTeacher
);
router.delete(
  '/teachers/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  TeachersController.deleteTeacher
);

// --- Class & Division Management ---
router.get('/classes', authenticateToken, requireSchoolTenant, ClassesController.listClasses);
router.get('/classes/:id', authenticateToken, requireSchoolTenant, ClassesController.getClassById);
router.post(
  '/classes',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  validateBody(classCreateSchema),
  ClassesController.createClass
);
router.put(
  '/classes/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  ClassesController.updateClass
);
router.delete(
  '/classes/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  ClassesController.deleteClass
);

// --- Subject Management ---
router.get('/subjects', authenticateToken, requireSchoolTenant, SubjectsController.listSubjects);
router.post(
  '/subjects',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  validateBody(subjectCreateSchema),
  SubjectsController.createSubject
);
router.put(
  '/subjects/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  SubjectsController.updateSubject
);
router.delete(
  '/subjects/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  SubjectsController.deleteSubject
);

// --- Attendance Module ---
router.get('/attendance', authenticateToken, requireSchoolTenant, AttendanceController.getClassAttendance);
router.post(
  '/attendance',
  authenticateToken,
  requireSchoolTenant,
  validateBody(attendanceBatchSchema),
  AttendanceController.saveClassAttendance
);
router.get('/attendance/student/:studentId', authenticateToken, requireSchoolTenant, AttendanceController.getStudentAttendance);

// --- Examination & Marks ---
router.get('/exams', authenticateToken, requireSchoolTenant, ExamsController.listExams);
router.post(
  '/exams',
  authenticateToken,
  requireSchoolTenant,
  validateBody(examCreateSchema),
  ExamsController.createExam
);
router.get('/exams/:examId/marks', authenticateToken, requireSchoolTenant, ExamsController.getExamMarks);
router.post(
  '/exams/marks',
  authenticateToken,
  requireSchoolTenant,
  validateBody(marksBatchSchema),
  ExamsController.saveExamMarks
);

// --- Fees Management ---
router.get('/fees/structures', authenticateToken, requireSchoolTenant, FeesController.listFeeStructures);
router.post(
  '/fees/structures',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]), // Staff cannot manage fee config
  validateBody(feeStructureSchema),
  FeesController.createFeeStructure
);
router.post(
  '/fees/payments',
  authenticateToken,
  requireSchoolTenant,
  validateBody(feePaymentSchema),
  FeesController.recordPayment
);
router.get('/fees/students/:studentId', authenticateToken, requireSchoolTenant, FeesController.getStudentFeeStatus);
router.get('/fees/receipts/:receiptNo/download', FeesController.downloadReceipt);

// --- Certificate Module ---
router.get('/certificates', authenticateToken, requireSchoolTenant, CertificatesController.listCertificates);
router.post(
  '/certificates/generate',
  authenticateToken,
  requireSchoolTenant,
  validateBody(certificateGenerateSchema),
  CertificatesController.generateCertificate
);
router.get('/certificates/:certificateNo/download', CertificatesController.downloadCertificate);

// --- Timetable ---
router.get('/timetable', authenticateToken, requireSchoolTenant, TimetableController.getTimetable);
router.post(
  '/timetable',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  validateBody(timetableSchema),
  TimetableController.saveEntry
);
router.delete(
  '/timetable/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  TimetableController.deleteEntry
);

// --- Notices ---
router.get('/notices', authenticateToken, requireSchoolTenant, NoticesController.listNotices);
router.post(
  '/notices',
  authenticateToken,
  requireSchoolTenant,
  validateBody(noticeCreateSchema),
  NoticesController.createNotice
);
router.put('/notices/:id', authenticateToken, requireSchoolTenant, NoticesController.updateNotice);
router.delete(
  '/notices/:id',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  NoticesController.deleteNotice
);

// --- Reports ---
router.get('/reports/school-summary', authenticateToken, requireSchoolTenant, ReportsController.getSchoolSummary);
router.get('/reports/student/:studentId', authenticateToken, requireSchoolTenant, ReportsController.getStudentReport);
router.get('/reports/student/:studentId/download', ReportsController.downloadStudentReportPdf);
router.get('/reports/attendance', authenticateToken, requireSchoolTenant, ReportsController.getAttendanceReport);
router.get('/reports/fees', authenticateToken, requireSchoolTenant, ReportsController.getFeeReport);
router.get('/reports/results', authenticateToken, requireSchoolTenant, ReportsController.getResultReport);
router.get('/reports/classes', authenticateToken, requireSchoolTenant, ReportsController.getClassReport);
router.get('/reports/teachers', authenticateToken, requireSchoolTenant, ReportsController.getTeacherReport);
router.post(
  '/reports/internship/generate',
  authenticateToken,
  requireSchoolTenant,
  validateBody(internshipReportGenerateSchema),
  ReportsController.generateInternshipReport
);
router.get('/reports/internship/:fileName/download', ReportsController.downloadInternshipReport);

// --- Settings & Continuous DB Backup ---
router.get('/settings', authenticateToken, requireSchoolTenant, SettingsController.getSettings);
router.put(
  '/settings',
  authenticateToken,
  requireSchoolTenant,
  requireRole([Role.ADMIN]),
  validateBody(settingUpdateSchema),
  SettingsController.updateSettings
);
router.post(
  '/settings/backup',
  authenticateToken,
  requireRole([Role.ADMIN, Role.SUPERADMIN]),
  SettingsController.triggerBackup
);
router.get(
  '/settings/backups',
  authenticateToken,
  requireRole([Role.ADMIN, Role.SUPERADMIN]),
  SettingsController.listBackups
);
router.get(
  '/settings/backups/:filename',
  authenticateToken,
  requireRole([Role.ADMIN, Role.SUPERADMIN]),
  SettingsController.downloadBackupFile
);

export default router;
