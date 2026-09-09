import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../config/db';
import { Role } from '@prisma/client';

export class ClientsController {
  public static async listClients(req: Request, res: Response): Promise<void> {
    try {
      const { status, includeDeleted } = req.query;

      const where: any = {
        id: { gt: 1 }, // Exclude platform admin reserved row
      };

      if (status) {
        where.status = String(status);
      } else if (includeDeleted !== 'true') {
        where.status = { not: 'deleted' };
      }

      const clients = await prisma.client.findMany({
        where,
        include: {
          _count: {
            select: {
              students: true,
              teachers: true,
              users: true,
              classes: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({ clients });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Failed to fetch clients' });
    }
  }

  public static async getClient(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id, 10);
      if (isNaN(id) || id <= 1) {
        res.status(404).json({ error: 'Client not found' });
        return;
      }

      const client = await prisma.client.findUnique({
        where: { id },
        include: {
          users: {
            select: { id: true, name: true, email: true, role: true, createdAt: true },
          },
          _count: {
            select: {
              students: true,
              teachers: true,
              classes: true,
            },
          },
        },
      });

      if (!client) {
        res.status(404).json({ error: 'Client not found' });
        return;
      }

      res.status(200).json({ client });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createClient(req: Request, res: Response): Promise<void> {
    try {
      const { name, slug, adminName, adminEmail, adminPassword } = req.body;

      if (!name || !slug || !adminName || !adminEmail || !adminPassword) {
        res.status(400).json({ error: 'All fields are required: name, slug, adminName, adminEmail, adminPassword' });
        return;
      }

      const cleanSlug = slug.toLowerCase().trim().replace(/[^a-z0-9-]/g, '-');

      // Check slug uniqueness
      const existingSlug = await prisma.client.findUnique({
        where: { slug: cleanSlug },
      });
      if (existingSlug) {
        res.status(409).json({ error: 'School with this slug or code already exists' });
        return;
      }

      // Check email uniqueness
      const existingEmail = await prisma.user.findUnique({
        where: { email: adminEmail.toLowerCase().trim() },
      });
      if (existingEmail) {
        res.status(409).json({ error: 'User with this admin email already exists' });
        return;
      }

      const passwordHash = await bcrypt.hash(adminPassword, 10);

      // Atomic provision of client + admin user + initial settings
      const result = await prisma.$transaction(async (tx) => {
        const newClient = await tx.client.create({
          data: {
            name,
            slug: cleanSlug,
            status: 'active',
            adminEmail: adminEmail.toLowerCase().trim(),
          },
        });

        const newAdmin = await tx.user.create({
          data: {
            clientId: newClient.id,
            name: adminName,
            email: adminEmail.toLowerCase().trim(),
            passwordHash,
            role: Role.ADMIN,
          },
        });

        // Initialize default settings for school
        await tx.setting.createMany({
          data: [
            { clientId: newClient.id, key: 'school_name', value: name },
            { clientId: newClient.id, key: 'academic_year', value: '2025-2026' },
            { clientId: newClient.id, key: 'school_email', value: adminEmail },
          ],
        });

        // Initialize default starter classes so the school is immediately operational
        await tx.class.createMany({
          data: [
            { clientId: newClient.id, name: '10', division: 'A', academicYear: '2025-2026' },
            { clientId: newClient.id, name: '9', division: 'A', academicYear: '2025-2026' },
            { clientId: newClient.id, name: '8', division: 'A', academicYear: '2025-2026' },
          ],
        });

        return { client: newClient, admin: newAdmin };
      });

      res.status(201).json({
        message: 'Client school and administrator created successfully',
        client: result.client,
        admin: {
          id: result.admin.id,
          name: result.admin.name,
          email: result.admin.email,
          role: result.admin.role,
        },
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Failed to create client' });
    }
  }

  public static async updateStatus(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id, 10);
      const { status } = req.body;

      if (isNaN(id) || id <= 1) {
        res.status(400).json({ error: 'Cannot modify reserved Platform Admin client' });
        return;
      }

      if (!['active', 'suspended'].includes(status)) {
        res.status(400).json({ error: 'Invalid status. Must be "active" or "suspended"' });
        return;
      }

      const updated = await prisma.client.update({
        where: { id },
        data: { status },
      });

      res.status(200).json({
        message: `Client status updated to ${status}`,
        client: updated,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Failed to update client status' });
    }
  }

  public static async deleteClient(req: Request, res: Response): Promise<void> {
    try {
      const id = parseInt(req.params.id, 10);

      if (isNaN(id) || id <= 1) {
        res.status(400).json({ error: 'Cannot delete reserved Platform Admin client' });
        return;
      }

      // Soft delete
      const deleted = await prisma.client.update({
        where: { id },
        data: { status: 'deleted' },
      });

      res.status(200).json({
        message: 'Client school deactivated successfully (soft-deleted)',
        client: deleted,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Failed to deactivate client' });
    }
  }

  public static async getPlatformStats(req: Request, res: Response): Promise<void> {
    try {
      const [totalClients, activeClients, suspendedClients, totalStudents, totalUsers] = await Promise.all([
        prisma.client.count({ where: { id: { gt: 1 }, status: { not: 'deleted' } } }),
        prisma.client.count({ where: { id: { gt: 1 }, status: 'active' } }),
        prisma.client.count({ where: { id: { gt: 1 }, status: 'suspended' } }),
        prisma.student.count(),
        prisma.user.count({ where: { clientId: { gt: 1 } } }),
      ]);

      res.status(200).json({
        totalClients,
        activeClients,
        suspendedClients,
        totalStudents,
        totalUsers,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Failed to fetch platform stats' });
    }
  }
}
