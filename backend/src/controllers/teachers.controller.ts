import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class TeachersController {
  public static async listTeachers(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const search = (req.query.search as string)?.trim() || '';
      const status = req.query.status as string;

      const whereClause: any = { clientId };
      if (search) {
        whereClause.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
          { contact: { contains: search, mode: 'insensitive' } },
        ];
      }
      if (status) {
        whereClause.status = status;
      }

      const teachers = await prisma.teacher.findMany({
        where: whereClause,
        orderBy: { name: 'asc' },
        include: {
          subjects: {
            where: { clientId },
            include: {
              class: { select: { name: true, division: true } },
            },
          },
        },
      });

      res.status(200).json({ data: teachers });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getTeacherById(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const teacher = await prisma.teacher.findFirst({
        where: { id, clientId },
        include: {
          subjects: {
            where: { clientId },
            include: { class: true },
          },
        },
      });

      if (!teacher) {
        res.status(404).json({ error: 'Teacher not found' });
        return;
      }

      res.status(200).json({ teacher });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createTeacher(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { name, email, contact, qualification, status } = cleanBody;

      const existing = await prisma.teacher.findFirst({
        where: { clientId, email: email.toLowerCase().trim() },
      });
      if (existing) {
        res.status(409).json({ error: 'Teacher with this email already exists in your school' });
        return;
      }

      const teacher = await prisma.teacher.create({
        data: {
          clientId,
          name,
          email: email.toLowerCase().trim(),
          contact,
          qualification: qualification || 'Bachelor of Education',
          status: status || 'Active',
        },
      });

      res.status(201).json({ message: 'Teacher created successfully', teacher });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async updateTeacher(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const cleanBody = sanitizeTenantInput(req.body);

      const existing = await prisma.teacher.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Teacher not found' });
        return;
      }

      const updated = await prisma.teacher.update({
        where: { id },
        data: cleanBody,
      });
      res.status(200).json({ message: 'Teacher updated successfully', teacher: updated });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async deleteTeacher(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      const existing = await prisma.teacher.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Teacher not found' });
        return;
      }

      // Disconnect subjects
      await prisma.subject.updateMany({
        where: { teacherId: id, clientId },
        data: { teacherId: null },
      });

      await prisma.teacher.delete({ where: { id } });
      res.status(200).json({ message: 'Teacher deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
