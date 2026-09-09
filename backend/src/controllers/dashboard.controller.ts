import { Request, Response } from 'express';
import prisma from '../config/db';
import { AttendanceStatus } from '@prisma/client';
import { getTenantId } from '../utils/tenant.util';

export class DashboardController {
  public static async getSummary(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const [totalStudents, totalTeachers, totalClasses] = await Promise.all([
        prisma.student.count({ where: { clientId, status: 'ACTIVE' } }),
        prisma.teacher.count({ where: { clientId, status: 'Active' } }),
        prisma.class.count({ where: { clientId } }),
      ]);

      // Total Fees Collected for this tenant
      const feeSum = await prisma.feePayment.aggregate({
        where: { clientId },
        _sum: { amountPaid: true },
      });
      const totalFeesCollected = Number(feeSum._sum.amountPaid || 0);

      // Pending Fees for this tenant
      const feeStructures = await prisma.feeStructure.findMany({ where: { clientId } });
      let totalFeeRequired = 0;
      for (const fs of feeStructures) {
        const studentCount = await prisma.student.count({
          where: { clientId, classId: fs.classId, status: 'ACTIVE' },
        });
        totalFeeRequired += Number(fs.amount) * studentCount;
      }
      const pendingFees = Math.max(0, totalFeeRequired - totalFeesCollected);

      // Today's attendance for this tenant
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const latestAttendanceRecord = await prisma.attendance.findFirst({
        where: { clientId },
        orderBy: { date: 'desc' },
      });

      const targetDate = latestAttendanceRecord ? latestAttendanceRecord.date : today;

      const [presentCount, absentCount, leaveCount] = await Promise.all([
        prisma.attendance.count({ where: { clientId, date: targetDate, status: AttendanceStatus.PRESENT } }),
        prisma.attendance.count({ where: { clientId, date: targetDate, status: AttendanceStatus.ABSENT } }),
        prisma.attendance.count({ where: { clientId, date: targetDate, status: AttendanceStatus.LEAVE } }),
      ]);

      const totalMarked = presentCount + absentCount + leaveCount;
      const attendancePercentage = totalMarked > 0 ? Math.round((presentCount / totalMarked) * 100) : 100;

      // Recent Admissions for this tenant (last 5)
      const recentAdmissions = await prisma.student.findMany({
        where: { clientId },
        take: 5,
        orderBy: { admissionDate: 'desc' },
        include: {
          class: { select: { name: true, division: true } },
        },
      });

      // Recent Notices for this tenant (last 3)
      const recentNotices = await prisma.notice.findMany({
        where: { clientId },
        take: 3,
        orderBy: { postedDate: 'desc' },
      });

      // Dynamic monthly fee collection overview from actual database payments
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const payments = await prisma.feePayment.findMany({
        where: { clientId },
        select: { amountPaid: true, paymentDate: true },
      });

      const now = new Date();
      const monthlyFees: { month: string; collected: number; pending: number }[] = [];
      for (let i = 5; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const mName = monthNames[d.getMonth()];
        const y = d.getFullYear();
        const m = d.getMonth();

        const monthCollected = payments
          .filter((p) => {
            const pDate = new Date(p.paymentDate);
            return pDate.getFullYear() === y && pDate.getMonth() === m;
          })
          .reduce((sum, p) => sum + Number(p.amountPaid), 0);

        const monthPending = Math.round(pendingFees / 6);

        monthlyFees.push({
          month: mName,
          collected: monthCollected,
          pending: monthPending,
        });
      }

      res.status(200).json({
        summary: {
          totalStudents,
          totalTeachers,
          totalClasses,
          totalFeesCollected,
          pendingFees,
          attendance: {
            percentage: attendancePercentage,
            present: presentCount,
            absent: absentCount,
            leave: leaveCount,
            date: targetDate.toISOString().split('T')[0],
          },
        },
        recentAdmissions: recentAdmissions.map((s) => ({
          id: s.id,
          name: s.name,
          admissionNumber: s.admissionNumber,
          class: `${s.class.name}-${s.class.division}`,
          date: s.admissionDate.toISOString().split('T')[0],
        })),
        recentNotices: recentNotices.map((n) => ({
          id: n.id,
          title: n.title,
          body: n.body,
          date: n.postedDate.toISOString().split('T')[0],
        })),
        feeCollectionOverview: monthlyFees,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
