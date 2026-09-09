import request from 'supertest';
import app from '../src/server';
import prisma from '../src/config/db';

describe('Auth & RBAC Module Unit/Integration Tests', () => {
  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should return 200 and health status on /api/health', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });

  it('should fail login when email format is invalid (400 Bad Request)', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'not-an-email',
      password: 'short',
    });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('Validation failed');
    expect(res.body.details.length).toBeGreaterThan(0);
  });

  it('should fail login with incorrect password (401 Unauthorized)', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'admin@auraems.com',
      password: 'WrongPassword123',
    });
    expect(res.status).toBe(401);
    expect(res.body.error).toBe('Invalid email or password');
  });

  it('should successfully log in admin and return a valid JWT token', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'admin@auraems.com',
      password: 'Admin@123',
    });
    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.user.role).toBe('ADMIN');
  });

  it('should successfully log in staff and return STAFF role', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'staff@auraems.com',
      password: 'Staff@123',
    });
    expect(res.status).toBe(200);
    expect(res.body.token).toBeDefined();
    expect(res.body.user.role).toBe('STAFF');
  });

  it('should block staff user from creating users (403 Forbidden)', async () => {
    // 1. Log in as staff
    const staffLogin = await request(app).post('/api/auth/login').send({
      email: 'staff@auraems.com',
      password: 'Staff@123',
    });
    const staffToken = staffLogin.body.token;

    // 2. Try to create user
    const res = await request(app)
      .post('/api/auth/users')
      .set('Authorization', `Bearer ${staffToken}`)
      .send({
        name: 'New Staff',
        email: 'newstaff@auraems.com',
        password: 'Password123',
        role: 'STAFF',
      });

    expect(res.status).toBe(403);
    expect(res.body.error).toMatch(/Forbidden/);
  });
});
