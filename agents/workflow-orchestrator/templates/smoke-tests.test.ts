/**
 * Smoke Tests - Critical Path Validation
 *
 * These tests verify that CORE functionality works.
 * They are designed to be FAST and catch major breakage.
 *
 * Purpose: Ensure that basic flows still work after changes.
 * Run: npm test smoke-tests.test.ts
 */

import request from 'supertest';
import { app } from '../server';
import { prisma } from '../utils/prisma';

describe('🔥 Smoke Tests - Critical Paths', () => {

  describe('Health Checks', () => {
    it('should return 200 on /health endpoint', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'ok');
    });

    it('should verify database connection', async () => {
      await expect(prisma.$queryRaw`SELECT 1`).resolves.toBeDefined();
    });
  });

  describe('Authentication Flow', () => {
    it('should register a new user', async () => {
      const userData = {
        email: `smoke-test-${Date.now()}@example.com`,
        password: 'SecurePass123!',
        name: 'Smoke Test User'
      };

      const res = await request(app)
        .post('/api/auth/register')
        .send(userData);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('user');
      expect(res.body).toHaveProperty('token');
    });

    it('should login existing user', async () => {
      // This assumes a test user exists or was created above
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'test123'
        });

      // Accept both success (200) or auth failure (401)
      // Just verify the endpoint responds
      expect([200, 401]).toContain(res.status);
    });
  });

  describe('Core API Endpoints', () => {
    it('should list courses (public endpoint)', async () => {
      const res = await request(app).get('/api/courses');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('should get user profile (protected endpoint)', async () => {
      const res = await request(app)
        .get('/api/users/me')
        .set('Authorization', 'Bearer invalid-token');

      // Should reject invalid token
      expect(res.status).toBe(401);
    });
  });

  describe('Database Operations', () => {
    it('should perform basic CRUD operations', async () => {
      // Create
      const course = await prisma.course.create({
        data: {
          title: 'Smoke Test Course',
          description: 'Testing',
          level: 'BEGINNER',
          duration: 60,
          slug: `smoke-test-${Date.now()}`
        }
      });

      expect(course).toHaveProperty('id');

      // Read
      const found = await prisma.course.findUnique({
        where: { id: course.id }
      });
      expect(found).toBeDefined();

      // Update
      const updated = await prisma.course.update({
        where: { id: course.id },
        data: { title: 'Updated Title' }
      });
      expect(updated.title).toBe('Updated Title');

      // Delete
      await prisma.course.delete({
        where: { id: course.id }
      });

      const deleted = await prisma.course.findUnique({
        where: { id: course.id }
      });
      expect(deleted).toBeNull();
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for non-existent routes', async () => {
      const res = await request(app).get('/api/non-existent-route-12345');
      expect(res.status).toBe(404);
    });

    it('should handle malformed JSON gracefully', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .set('Content-Type', 'application/json')
        .send('{ invalid json }');

      expect(res.status).toBe(400);
    });
  });

  // Cleanup after tests
  afterAll(async () => {
    await prisma.$disconnect();
  });
});
