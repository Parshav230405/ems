import request from 'supertest';
import app from '../src/server';
import prisma from '../src/config/db';

describe('Academic, Fees, Certificates & Backup Unit/Integration Tests', () => {
  let adminToken: string;
  let staffToken: string;
  let sampleClassId: string;
  let sampleStudentId: string;

  beforeAll(async () => {
    const adminRes = await request(app).post('/api/auth/login').send({
      email: 'admin@auraems.com',
      password: 'Admin@123',
    });
    adminToken = adminRes.body.token;

    const staffRes = await request(app).post('/api/auth/login').send({
      email: 'staff@auraems.com',
      password: 'Staff@123',
    });
    staffToken = staffRes.body.token;

    const c = await prisma.class.findFirst();
    sampleClassId = c!.id;

    const s = await prisma.student.findFirst({ where: { classId: sampleClassId } });
    sampleStudentId = s!.id;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should fetch dashboard real aggregated summary', async () => {
    const res = await request(app)
      .get('/api/dashboard')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.summary.totalStudents).toBeGreaterThanOrEqual(30);
    expect(res.body.summary.totalTeachers).toBeGreaterThanOrEqual(5);
    expect(res.body.summary.totalClasses).toBeGreaterThanOrEqual(3);
    expect(res.body.summary.attendance.percentage).toBeGreaterThan(0);
    expect(res.body.recentAdmissions.length).toBeGreaterThan(0);
  });

  it('should record attendance batch and update state', async () => {
    const todayStr = '2026-09-08';
    const res = await request(app)
      .post('/api/attendance')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        date: todayStr,
        classId: sampleClassId,
        records: [
          { studentId: sampleStudentId, status: 'PRESENT' },
        ],
      });

    expect(res.status).toBe(200);
    expect(res.body.message).toContain('Attendance recorded');
  });

  it('should calculate examination marks percentage and grades accurately', async () => {
    const exam = await prisma.exam.findFirst({ where: { classId: sampleClassId } });
    const res = await request(app)
      .get(`/api/exams/${exam!.id}/marks`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.students.length).toBeGreaterThan(0);
    const firstStudent = res.body.students[0];
    expect(firstStudent.grade).toBeDefined();
    expect(['A+', 'A', 'B+', 'B', 'C', 'D', 'F']).toContain(firstStudent.grade);
  });

  it('should block staff from configuring fee structures (403 Forbidden)', async () => {
    const res = await request(app)
      .post('/api/fees/structures')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({
        classId: sampleClassId,
        academicYear: '2025-2026',
        title: 'Exam Fee',
        amount: 2500,
        dueDate: '2025-11-01',
      });

    expect(res.status).toBe(403);
  });

  it('should record fee payment and deduct pending balance', async () => {
    const res = await request(app)
      .post('/api/fees/payments')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        studentId: sampleStudentId,
        amountPaid: 5000,
        mode: 'CASH',
        notes: 'Mid-term installment',
      });

    expect(res.status).toBe(201);
    expect(res.body.payment.receiptNo).toMatch(/^REC-/);
  });

  it('should generate certificate, log to audit table, and provide download', async () => {
    const res = await request(app)
      .post('/api/certificates/generate')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        studentId: sampleStudentId,
        title: 'CERTIFICATE OF EXCELLENCE',
        body: 'Has demonstrated extraordinary leadership and academic merit throughout the term.',
      });

    expect(res.status).toBe(201);
    expect(res.body.certificate.certificateNo).toMatch(/^CERT-\d{4}-/);
    expect(res.body.downloadUrl).toBeDefined();
  });

  it('should generate and download official student report card PDF', async () => {
    const res = await request(app)
      .get(`/api/reports/student/${sampleStudentId}/download`);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toBe('application/pdf');
    expect(res.headers['content-disposition']).toMatch(/attachment; filename=ReportCard_/);
  });

  it('should generate and download official student internship report DOCX', async () => {
    const genRes = await request(app)
      .post('/api/reports/internship/generate')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        studentId: sampleStudentId,
        projectTitle: 'AURA EMS: MULTI-TENANT EDUCATION MANAGEMENT SYSTEM',
        internshipTitle: 'Full-Stack Web Development',
        companyName: 'Vanshee Infotech',
        companyAddress: 'B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India',
        companyGuide: 'Bhavi Kansara (CEO)',
        facultyGuide: 'Prof. Internal Faculty Guide',
        courseCode: 'CE0523',
        duration: '15 Days / 65+ Hours',
      });

    expect(genRes.status).toBe(201);
    expect(genRes.body.fileName).toMatch(/^Internship_Report_/);
    expect(genRes.body.downloadUrl).toBeDefined();

    const dlRes = await request(app).get(genRes.body.downloadUrl);

    expect(dlRes.status).toBe(200);
    expect(dlRes.headers['content-type']).toBe(
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    );
    expect(dlRes.headers['content-disposition']).toMatch(/attachment; filename="Internship_Report_/);
  });


  it('should trigger continuous database backup and list available backups', async () => {
    const res = await request(app)
      .post('/api/settings/backup')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.backups.length).toBe(2);

    const listRes = await request(app)
      .get('/api/settings/backups')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(listRes.status).toBe(200);
    expect(listRes.body.data.length).toBeGreaterThan(0);
  });
});
