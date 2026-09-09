import request from 'supertest';
import app from '../src/server';
import prisma from '../src/config/db';

describe('Student Management Module Unit/Integration Tests', () => {
  let adminToken: string;
  let staffToken: string;
  let sampleClassId: string;
  let createdStudentId: string;

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

    const classItem = await prisma.class.findFirst();
    sampleClassId = classItem!.id;
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should list students with pagination and active filter', async () => {
    const res = await request(app)
      .get('/api/students?page=1&limit=10')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeLessThanOrEqual(10);
    expect(res.body.meta.total).toBeGreaterThanOrEqual(30);
    expect(res.body.meta.page).toBe(1);
  });

  it('should search students by name and admission number', async () => {
    const res = await request(app)
      .get('/api/students?search=Rahul')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBeGreaterThan(0);
    expect(res.body.data[0].name).toContain('Rahul');
  });

  it('should fail admitting student if required parent fields are missing (400)', async () => {
    const res = await request(app)
      .post('/api/students')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'Incomplete Student',
        // missing dob, parent details, classId
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Validation failed');
  });

  it('should admit a new student with auto-generated admission number', async () => {
    const res = await request(app)
      .post('/api/students')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        name: 'New Test Student',
        dob: '2012-04-10',
        gender: 'Male',
        classId: sampleClassId,
        parentName: 'Test Parent',
        parentContact: '9876500000',
        parentEmail: 'testparent@example.com',
      });

    expect(res.status).toBe(201);
    expect(res.body.student.admissionNumber).toMatch(/^ADM\d+/);
    createdStudentId = res.body.student.id;
  });

  it('should get full student profile with attendance rate and fee summary', async () => {
    const student = await prisma.student.findFirst({ where: { admissionNumber: 'ADM001' } });
    const res = await request(app)
      .get(`/api/students/${student!.id}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.student.name).toBe('Rahul Patel');
    expect(res.body.analytics.attendanceRate).toBeGreaterThan(0);
    expect(res.body.analytics.feeSummary.totalFee).toBe(50000);
    expect(res.body.analytics.feeSummary.totalPaid).toBeGreaterThanOrEqual(35000);
    expect(Math.max(0, res.body.analytics.feeSummary.totalFee - res.body.analytics.feeSummary.totalPaid)).toBe(
      res.body.analytics.feeSummary.pendingFee
    );
  });

  it('should block staff from deleting a student (403 Forbidden)', async () => {
    const res = await request(app)
      .delete(`/api/students/${createdStudentId}`)
      .set('Authorization', `Bearer ${staffToken}`);

    expect(res.status).toBe(403);
  });

  it('should allow admin to delete the test student', async () => {
    const res = await request(app)
      .delete(`/api/students/${createdStudentId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Student deleted successfully');
  });
});
