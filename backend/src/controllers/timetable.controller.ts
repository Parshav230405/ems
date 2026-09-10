import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';
import { PdfService } from '../services/pdf.service';

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
      const { classId, dayOfWeek, period, subjectId, startTime, endTime, isBreak } = cleanBody;

      let finalSubjectId = subjectId;
      if (isBreak || !subjectId) {
        let breakSubject = await prisma.subject.findFirst({
          where: { clientId, classId, name: 'Recess / Break' },
        });
        if (!breakSubject) {
          breakSubject = await prisma.subject.create({
            data: {
              clientId,
              classId,
              name: 'Recess / Break',
              code: 'BREAK',
            },
          });
        }
        finalSubjectId = breakSubject.id;
      }

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
          subjectId: finalSubjectId,
          startTime: startTime || null,
          endTime: endTime || null,
        },
        create: {
          clientId,
          classId,
          dayOfWeek,
          period,
          subjectId: finalSubjectId,
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

  public static async downloadTimetablePdf(req: Request, res: Response): Promise<void> {
    try {
      const { classId } = req.params;
      if (!classId) {
        res.status(400).json({ error: 'classId parameter is required' });
        return;
      }

      const classObj = await prisma.class.findUnique({
        where: { id: classId },
        include: { client: true },
      });

      if (!classObj) {
        res.status(404).json({ error: 'Class not found' });
        return;
      }

      const clientId = classObj.clientId;

      const [entries, schoolNameSetting, schoolTaglineSetting] = await Promise.all([
        prisma.timetable.findMany({
          where: { clientId, classId },
          orderBy: [{ dayOfWeek: 'asc' }, { period: 'asc' }],
          include: {
            subject: {
              include: {
                teacher: { select: { name: true } },
              },
            },
          },
        }),
        prisma.setting.findFirst({ where: { clientId, key: 'school_name' } }),
        prisma.setting.findFirst({ where: { clientId, key: 'school_tagline' } }),
      ]);

      const hasSaturday = entries.some((e) => e.dayOfWeek.toLowerCase() === 'saturday');
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
      if (hasSaturday) days.push('Saturday');

      const maxPeriod = Math.max(5, ...entries.map((e) => e.period));
      const periodList: Array<{ period: number; time: string }> = [];

      for (let p = 1; p <= maxPeriod; p++) {
        const matching = entries.find((e) => e.period === p && e.startTime && e.endTime);
        const timeStr = matching ? `${matching.startTime} - ${matching.endTime}` : '';
        periodList.push({ period: p, time: timeStr });
      }

      const formattedEntries = entries.map((e) => ({
        dayOfWeek: e.dayOfWeek,
        period: e.period,
        subjectName: e.subject.name,
        teacherName: e.subject.teacher?.name,
        startTime: e.startTime || undefined,
        endTime: e.endTime || undefined,
      }));

      PdfService.generateTimetablePdf(res, {
        schoolName: schoolNameSetting?.value || classObj.client.name,
        schoolTagline: schoolTaglineSetting?.value || 'Excellence in Education',
        className: `Class ${classObj.name}-${classObj.division}`,
        academicYear: classObj.academicYear,
        days,
        periods: periodList,
        entries: formattedEntries,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
