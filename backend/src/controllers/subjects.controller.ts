import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class SubjectsController {
  public static async listSubjects(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const classId = req.query.classId as string;
      const where: any = { clientId };
      if (classId) where.classId = classId;

      const subjects = await prisma.subject.findMany({
        where,
        orderBy: { name: 'asc' },
        include: {
          class: { select: { id: true, name: true, division: true } },
          teacher: { select: { id: true, name: true, email: true } },
        },
      });

      res.status(200).json({ data: subjects });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createSubject(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { name, code, classId, teacherId } = cleanBody;

      const subject = await prisma.subject.create({
        data: {
          clientId,
          name,
          code: code || null,
          classId,
          teacherId: teacherId || null,
        },
        include: {
          class: true,
          teacher: true,
        },
      });

      res.status(201).json({ message: 'Subject created successfully', subject });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async updateSubject(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const cleanBody = sanitizeTenantInput(req.body);

      const existing = await prisma.subject.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Subject not found' });
        return;
      }

      const updated = await prisma.subject.update({
        where: { id },
        data: cleanBody,
        include: {
          class: true,
          teacher: true,
        },
      });
      res.status(200).json({ message: 'Subject updated successfully', subject: updated });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async deleteSubject(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      const existing = await prisma.subject.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Subject not found' });
        return;
      }

      await prisma.timetable.deleteMany({ where: { subjectId: id, clientId } });
      await prisma.exam.deleteMany({ where: { subjectId: id, clientId } });
      await prisma.subject.delete({ where: { id } });
      res.status(200).json({ message: 'Subject deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
