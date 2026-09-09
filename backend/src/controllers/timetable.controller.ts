import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class TimetableController {
  public static async getTimetable(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { classId } = req.query;

      if (!classId) {
        res.status(400).json({ error: 'classId query parameter is required' });
        return;
      }

      const timetable = await prisma.timetable.findMany({
        where: { clientId, classId: classId as string },
        orderBy: [{ dayOfWeek: 'asc' }, { period: 'asc' }],
        include: {
          subject: {
            include: {
              teacher: { select: { id: true, name: true } },
            },
          },
        },
      });

      res.status(200).json({ data: timetable });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async saveEntry(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { classId, dayOfWeek, period, subjectId, startTime, endTime } = cleanBody;

      const entry = await prisma.timetable.upsert({
        where: {
          clientId_classId_dayOfWeek_period: {
            clientId,
            classId,
            dayOfWeek,
            period,
          },
        },
        update: {
          subjectId,
          startTime: startTime || null,
          endTime: endTime || null,
        },
        create: {
          clientId,
          classId,
          dayOfWeek,
          period,
          subjectId,
          startTime: startTime || null,
          endTime: endTime || null,
        },
        include: {
          subject: true,
        },
      });

      res.status(200).json({ message: 'Timetable entry updated', entry });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async deleteEntry(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      await prisma.timetable.deleteMany({
        where: { id, clientId },
      });

      res.status(200).json({ message: 'Timetable entry deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
