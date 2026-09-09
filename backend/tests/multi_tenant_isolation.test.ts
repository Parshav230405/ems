import request from 'supertest';
import app from '../src/server';
import prisma from '../src/config/db';

describe('Multi-Tenant Isolation & Superadmin Console Test Suite', () => {
  let superadminToken: string;
  let client2AdminToken: string;
  let client3AdminToken: string;
  let client3StudentId: string;
  let client2StudentId: string;

  beforeAll(async () => {
    // 1. Superadmin login
    const superRes = await request(app).post('/api/auth/login').send({
      email: 'superadmin@auraems.com',
      password: 'SuperAdmin@123',
    });
    expect(superRes.status).toBe(200);
    expect(superRes.body.user.role).toBe('SUPERADMIN');
    expect(superRes.body.user.clientId).toBe(1);
    superadminToken = superRes.body.token;

    // 2. Client 2 Admin login
    const c2Res = await request(app).post('/api/auth/login').send({
      email: 'admin@auraems.com',
      password: 'Admin@123',
    });
    expect(c2Res.status).toBe(200);
    expect(c2Res.body.user.clientId).toBe(2);
    client2AdminToken = c2Res.body.token;

    // 3. Client 3 Admin login
    const c3Res = await request(app).post('/api/auth/login').send({
      email: 'indus.admin@auraems.com',
      password: 'Admin@123',
    });
    expect(c3Res.status).toBe(200);
    expect(c3Res.body.user.clientId).toBe(3);
    client3AdminToken = c3Res.body.token;

    // Fetch IDs for cross-tenant verification
    const c3Student = await prisma.student.findFirst({
      where: { clientId: 3 },
    });
    expect(c3Student).not.toBeNull();
    client3StudentId = c3Student!.id;

    const c2Student = await prisma.student.findFirst({
      where: { clientId: 2, admissionNumber: 'ADM001' },
    });
    expect(c2Student).not.toBeNull();
    client2StudentId = c2Student!.id;
  });

  const testSlug = `greenwood-${Date.now()}`;
  const testEmail = `admin-${Date.now()}@greenwood.edu.in`;

  afterAll(async () => {
    await prisma.setting.deleteMany({ where: { client: { slug: { startsWith: 'greenwood' } } } });
    await prisma.user.deleteMany({ where: { email: { contains: 'greenwood' } } });
    await prisma.client.deleteMany({ where: { slug: { startsWith: 'greenwood' } } });
    await prisma.$disconnect();
  });

  describe('1. Cross-Tenant Data Isolation Enforcement', () => {
    it('Admin of Client 2 fetching student of Client 3 must receive 404 (isolation guarantee)', async () => {
      const res = await request(app)
        .get(`/api/students/${client3StudentId}`)
        .set('Authorization', `Bearer ${client2AdminToken}`);

      expect(res.status).toBe(404);
      expect(res.body.error).toBe('Student not found');
    });

    it('Admin of Client 3 fetching student of Client 2 must receive 404', async () => {
      const res = await request(app)
        .get(`/api/students/${client2StudentId}`)
        .set('Authorization', `Bearer ${client3AdminToken}`);

      expect(res.status).toBe(404);
      expect(res.body.error).toBe('Student not found');
    });

    it('Client 2 student list contains exactly Client 2 students and never leaks Client 3 students', async () => {
      const res = await request(app)
        .get('/api/students?limit=100')
        .set('Authorization', `Bearer ${client2AdminToken}`);

      expect(res.status).toBe(200);
      const studentNames = res.body.data.map((s: any) => s.name);
      expect(studentNames).not.toContain('Dev Patel'); // Dev Patel belongs to Client 3
      expect(res.body.data.every((s: any) => s.clientId === 2)).toBe(true);
    });

    it('Tenant ID cannot be spoofed in request payload (server derives from verified JWT)', async () => {
      const c2Class = await prisma.class.findFirst({ where: { clientId: 2 } });

      const res = await request(app)
        .post('/api/students')
        .set('Authorization', `Bearer ${client2AdminToken}`)
        .send({
          clientId: 3, // Attacker attempts to inject student into Client 3
          client_id: 3,
          admissionNumber: 'SPOOF01',
          name: 'Spoof Student',
          dob: '2012-01-01',
          gender: 'Male',
          classId: c2Class!.id,
          parentName: 'Spoof Parent',
          parentContact: '9000000000',
        });

      expect(res.status).toBe(201);
      // Student must belong to Client 2, not Client 3!
      expect(res.body.student.clientId).toBe(2);

      // Clean up spoof student
      await prisma.student.delete({ where: { id: res.body.student.id } });
    });
  });

  describe('2. Account Suspension Security Check', () => {
    it('Suspended school user is blocked from logging in with 403 and descriptive message', async () => {
      const res = await request(app).post('/api/auth/login').send({
        email: 'suspended.admin@auraems.com',
        password: 'Admin@123',
      });

      expect(res.status).toBe(403);
      expect(res.body.code).toBe('ACCOUNT_SUSPENDED');
      expect(res.body.error).toContain('suspended');
    });
  });

  describe('3. Superadmin Client Console Management', () => {
    let newlyCreatedClientId: number;

    it('Non-superadmin cannot access client management endpoints (403 Forbidden)', async () => {
      const res = await request(app)
        .get('/api/clients')
        .set('Authorization', `Bearer ${client2AdminToken}`);

      expect(res.status).toBe(403);
    });

    it('Superadmin can retrieve platform statistics', async () => {
      const res = await request(app)
        .get('/api/clients/stats')
        .set('Authorization', `Bearer ${superadminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.totalClients).toBeGreaterThanOrEqual(3);
      expect(res.body.activeClients).toBeGreaterThanOrEqual(2);
      expect(res.body.suspendedClients).toBeGreaterThanOrEqual(1);
    });

    it('Superadmin can list clients excluding reserved Platform Admin row (id = 1)', async () => {
      const res = await request(app)
        .get('/api/clients')
        .set('Authorization', `Bearer ${superadminToken}`);

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.clients)).toBe(true);
      expect(res.body.clients.every((c: any) => c.id > 1)).toBe(true);
    });

    it('Superadmin can create a new client and its admin user atomically', async () => {
      const res = await request(app)
        .post('/api/clients')
        .set('Authorization', `Bearer ${superadminToken}`)
        .send({
          name: 'Greenwood High International',
          slug: testSlug,
          adminName: 'Greenwood Admin',
          adminEmail: testEmail,
          adminPassword: 'Password@123',
        });

      expect(res.status).toBe(201);
      expect(res.body.client.name).toBe('Greenwood High International');
      expect(res.body.client.slug).toBe(testSlug);
      expect(res.body.admin.email).toBe(testEmail);
      newlyCreatedClientId = res.body.client.id;

      // Verify the new admin can log in
      const loginRes = await request(app).post('/api/auth/login').send({
        email: testEmail,
        password: 'Password@123',
      });
      expect(loginRes.status).toBe(200);
      expect(loginRes.body.user.clientId).toBe(newlyCreatedClientId);
    });

    it('Superadmin can suspend and reactivate a client school', async () => {
      // Suspend
      const suspendRes = await request(app)
        .patch(`/api/clients/${newlyCreatedClientId}/status`)
        .set('Authorization', `Bearer ${superadminToken}`)
        .send({ status: 'suspended' });

      expect(suspendRes.status).toBe(200);
      expect(suspendRes.body.client.status).toBe('suspended');

      // Attempt login should now fail with 403
      const loginAttempt = await request(app).post('/api/auth/login').send({
        email: testEmail,
        password: 'Password@123',
      });
      expect(loginAttempt.status).toBe(403);

      // Reactivate
      const reactivateRes = await request(app)
        .patch(`/api/clients/${newlyCreatedClientId}/status`)
        .set('Authorization', `Bearer ${superadminToken}`)
        .send({ status: 'active' });

      expect(reactivateRes.status).toBe(200);
      expect(reactivateRes.body.client.status).toBe('active');

      // Login succeeds again
      const loginSuccess = await request(app).post('/api/auth/login').send({
        email: testEmail,
        password: 'Password@123',
      });
      expect(loginSuccess.status).toBe(200);
    });

    it('Reserved Platform Admin client (id = 1) is protected from modification or deletion', async () => {
      const patchRes = await request(app)
        .patch('/api/clients/1/status')
        .set('Authorization', `Bearer ${superadminToken}`)
        .send({ status: 'suspended' });

      expect(patchRes.status).toBe(400);

      const deleteRes = await request(app)
        .delete('/api/clients/1')
        .set('Authorization', `Bearer ${superadminToken}`);

      expect(deleteRes.status).toBe(400);
    });

    it('Superadmin is blocked from accessing school-level tenant views (must use Client Console)', async () => {
      const studentRes = await request(app)
        .get('/api/students')
        .set('Authorization', `Bearer ${superadminToken}`);

      expect(studentRes.status).toBe(403);

      const dashboardRes = await request(app)
        .get('/api/dashboard')
        .set('Authorization', `Bearer ${superadminToken}`);

      expect(dashboardRes.status).toBe(403);
    });
  });
});
