import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class ClassesController {
  public static async listClasses(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const classes = await prisma.class.findMany({
        where: { clientId },
        orderBy: [{ name: 'asc' }, { division: 'asc' }],
        include: {
          _count: {
            select: { students: true, subjects: true },
          },
        },
      });

      res.status(200).json({ data: classes });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getClassById(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const classItem = await prisma.class.findFirst({
        where: { id, clientId },
        include: {
          subjects: {
            where: { clientId },
            include: { teacher: true },
          },
          students: {
            where: { clientId },
            select: { id: true, name: true, admissionNumber: true, status: true },
          },
          feeStructure: {
            where: { clientId },
          },
        },
      });

      if (!classItem) {
        res.status(404).json({ error: 'Class not found' });
        return;
      }

      res.status(200).json({ class: classItem });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createClass(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { name, division, academicYear } = cleanBody;

      const existing = await prisma.class.findFirst({
        where: {
          clientId,
          name: name.trim(),
          division: division.trim().toUpperCase(),
          academicYear: academicYear.trim(),
        },
      });

      if (existing) {
        res.status(409).json({ error: `Class ${name}-${division} for ${academicYear} already exists in your school` });
        return;
      }

      const newClass = await prisma.class.create({
        data: {
          clientId,
          name: name.trim(),
          division: division.trim().toUpperCase(),
          academicYear: academicYear.trim(),
        },
      });

      res.status(201).json({ message: 'Class created successfully', class: newClass });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async updateClass(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const cleanBody = sanitizeTenantInput(req.body);

      const existing = await prisma.class.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Class not found' });
        return;
      }

      const updated = await prisma.class.update({
        where: { id },
        data: cleanBody,
      });
      res.status(200).json({ message: 'Class updated successfully', class: updated });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async deleteClass(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      const existing = await prisma.class.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Class not found' });
        return;
      }

      const studentCount = await prisma.student.count({ where: { classId: id, clientId } });
      if (studentCount > 0) {
        res.status(400).json({
          error: `Cannot delete class containing ${studentCount} active students. Please reassign students first.`,
        });
        return;
      }

      await prisma.timetable.deleteMany({ where: { classId: id, clientId } });
      await prisma.feeStructure.deleteMany({ where: { classId: id, clientId } });
      await prisma.subject.deleteMany({ where: { classId: id, clientId } });
      await prisma.class.delete({ where: { id } });

      res.status(200).json({ message: 'Class deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
