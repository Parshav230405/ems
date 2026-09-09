import { Request, Response } from 'express';
import prisma from '../config/db';
import { AttendanceStatus } from '@prisma/client';
import { getTenantId } from '../utils/tenant.util';

export class AttendanceController {
  public static async getClassAttendance(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { classId, date } = req.query;

      if (!classId || !date) {
        res.status(400).json({ error: 'classId and date (YYYY-MM-DD) query parameters are required' });
        return;
      }

      const targetDate = new Date(date as string);
      targetDate.setHours(0, 0, 0, 0);

      // Get all active students in this class for this tenant
      const students = await prisma.student.findMany({
        where: { clientId, classId: classId as string, status: 'ACTIVE' },
        orderBy: { admissionNumber: 'asc' },
        select: { id: true, name: true, admissionNumber: true },
      });

      // Get existing attendance records for this date and tenant
      const attendanceRecords = await prisma.attendance.findMany({
        where: {
          clientId,
          date: targetDate,
          studentId: { in: students.map((s) => s.id) },
        },
      });

      const attendanceMap = new Map<string, AttendanceStatus>();
      attendanceRecords.forEach((rec) => {
        attendanceMap.set(rec.studentId, rec.status);
      });

      const result = students.map((student, index) => ({
        rollNo: index + 1,
        studentId: student.id,
        studentName: student.name,
        admissionNumber: student.admissionNumber,
        status: attendanceMap.get(student.id) || AttendanceStatus.PRESENT,
        isMarked: attendanceMap.has(student.id),
      }));

      res.status(200).json({
        classId,
        date: date as string,
        data: result,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async saveClassAttendance(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { date, records } = req.body;
      const markedBy = req.user?.id;

      const targetDate = new Date(date);
      targetDate.setHours(0, 0, 0, 0);

      // Execute upserts in a transaction with tenant isolation
      await prisma.$transaction(
        records.map((r: { studentId: string; status: AttendanceStatus }) =>
          prisma.attendance.upsert({
            where: {
              clientId_studentId_date: {
                clientId,
                studentId: r.studentId,
                date: targetDate,
              },
            },
            update: {
              status: r.status,
              markedBy,
            },
            create: {
              clientId,
              studentId: r.studentId,
              date: targetDate,
              status: r.status,
              markedBy,
            },
          })
        )
      );

      res.status(200).json({
        message: `Attendance recorded for ${records.length} students on ${date}`,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getStudentAttendance(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { studentId } = req.params;

      const records = await prisma.attendance.findMany({
        where: { studentId, clientId },
        orderBy: { date: 'desc' },
      });

      const present = records.filter((r) => r.status === 'PRESENT').length;
      const absent = records.filter((r) => r.status === 'ABSENT').length;
      const leave = records.filter((r) => r.status === 'LEAVE').length;
      const total = records.length;
      const percentage = total > 0 ? Math.round((present / total) * 100) : 100;

      res.status(200).json({
        summary: { total, present, absent, leave, percentage },
        records,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
