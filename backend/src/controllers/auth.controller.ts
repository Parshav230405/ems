import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';
import { Role } from '@prisma/client';
import { getTenantId } from '../utils/tenant.util';

const JWT_SECRET = process.env.JWT_SECRET || 'aura_ems_jwt_super_secret_key_2026_production_grade';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

export class AuthController {
  public static async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase().trim() },
        include: { client: true },
      });

      if (!user) {
        res.status(401).json({ error: 'Invalid email or password' });
        return;
      }

      // Check tenant status (unless platform owner)
      if (user.clientId !== 1 && user.client) {
        if (user.client.status === 'suspended') {
          res.status(403).json({
            error: 'Your school account is suspended. Please contact platform administration.',
            code: 'ACCOUNT_SUSPENDED',
          });
          return;
        }
        if (user.client.status === 'deleted') {
          res.status(403).json({
            error: 'Your school account has been deactivated. Please contact platform administration.',
            code: 'ACCOUNT_DEACTIVATED',
          });
          return;
        }
      }

      const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
      if (!isPasswordValid) {
        res.status(401).json({ error: 'Invalid email or password' });
        return;
      }

      const token = jwt.sign(
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          clientId: user.clientId,
        },
        JWT_SECRET,
        { expiresIn: (process.env.JWT_EXPIRES_IN || '7d') as any }
      );

      res.status(200).json({
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          clientId: user.clientId,
          clientName: user.client?.name || 'AURA EMS',
          clientSlug: user.client?.slug || '',
        },
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message || 'Login failed' });
    }
  }

  public static async me(req: Request, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Not authenticated' });
        return;
      }

      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        include: { client: true },
      });

      if (!user) {
        res.status(404).json({ error: 'User not found' });
        return;
      }

      res.status(200).json({
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          clientId: user.clientId,
          clientName: user.client?.name || 'AURA EMS',
          clientSlug: user.client?.slug || '',
          createdAt: user.createdAt,
        },
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createUser(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { name, email, password, role } = req.body;

      // School admins cannot create superadmins
      if (role === Role.SUPERADMIN) {
        res.status(403).json({ error: 'Cannot create superadmin user via school admin portal' });
        return;
      }

      const existingUser = await prisma.user.findUnique({
        where: { email: email.toLowerCase().trim() },
      });

      if (existingUser) {
        res.status(409).json({ error: 'User with this email already exists' });
        return;
      }

      const passwordHash = await bcrypt.hash(password, 10);
      const newUser = await prisma.user.create({
        data: {
          clientId,
          name,
          email: email.toLowerCase().trim(),
          passwordHash,
          role: role || Role.STAFF,
        },
        select: { id: true, name: true, email: true, role: true, clientId: true, createdAt: true },
      });

      res.status(201).json({
        message: 'User created successfully',
        user: newUser,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async listUsers(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const users = await prisma.user.findMany({
        where: { clientId },
        select: { id: true, name: true, email: true, role: true, clientId: true, createdAt: true },
        orderBy: { createdAt: 'desc' },
      });
      res.status(200).json({ users });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
