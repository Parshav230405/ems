import { Request, Response } from 'express';
import prisma from '../config/db';
import { StudentStatus } from '@prisma/client';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';
import { parseFlexibleDateString } from '../validators/schemas';

export class StudentsController {
  public static async listStudents(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 15;
      const search = (req.query.search as string)?.trim() || '';
      const classId = req.query.classId as string;
      const status = req.query.status as StudentStatus;

      const skip = (page - 1) * limit;

      const whereClause: any = { clientId };
      if (search) {
        whereClause.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { admissionNumber: { contains: search, mode: 'insensitive' } },
          { parentName: { contains: search, mode: 'insensitive' } },
          { parentContact: { contains: search, mode: 'insensitive' } },
        ];
      }
      if (classId) {
        whereClause.classId = classId;
      }
      if (status) {
        whereClause.status = status;
      }

      const [total, students] = await Promise.all([
        prisma.student.count({ where: whereClause }),
        prisma.student.findMany({
          where: whereClause,
          skip,
          take: limit,
          orderBy: { admissionNumber: 'asc' },
          include: {
            class: {
              select: { id: true, name: true, division: true, academicYear: true },
            },
          },
        }),
      ]);

      res.status(200).json({
        data: students,
        meta: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
        },
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getStudentById(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      const student = await prisma.student.findFirst({
        where: { id, clientId },
        include: {
          class: {
            include: {
              subjects: {
                where: { clientId },
                include: { teacher: { select: { id: true, name: true } } },
              },
              feeStructure: {
                where: { clientId },
              },
            },
          },
          feePayments: {
            where: { clientId },
            orderBy: { paymentDate: 'desc' },
          },
          attendance: {
            where: { clientId },
            orderBy: { date: 'desc' },
            take: 30,
          },
          marks: {
            where: { clientId },
            include: {
              exam: {
                include: { subject: true },
              },
            },
          },
          certificates: {
            where: { clientId },
            orderBy: { issuedDate: 'desc' },
          },
        },
      });

      if (!student) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      // Compute attendance stats
      const totalDays = student.attendance.length;
      const presentDays = student.attendance.filter((a) => a.status === 'PRESENT').length;
      const attendanceRate = totalDays > 0 ? Math.round((presentDays / totalDays) * 100) : 100;

      // Compute fee summary
      const totalFee = student.class.feeStructure.reduce(
        (sum, fs) => sum + Number(fs.amount),
        0
      );
      const totalPaid = student.feePayments.reduce(
        (sum, fp) => sum + Number(fp.amountPaid),
        0
      );
      const pendingFee = Math.max(0, totalFee - totalPaid);

      res.status(200).json({
        student,
        analytics: {
          attendanceRate,
          totalDaysMarked: totalDays,
          presentDays,
          feeSummary: {
            totalFee,
            totalPaid,
            pendingFee,
          },
        },
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createStudent(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const {
        name,
        dob,
        gender,
        classId,
        parentName,
        parentContact,
        parentEmail,
        admissionDate,
        status,
      } = cleanBody;

      let { admissionNumber } = cleanBody;

      // Auto-generate admission number if not specified (scoped to tenant)
      if (!admissionNumber) {
        const existingStudents = await prisma.student.findMany({
          where: { clientId, admissionNumber: { startsWith: 'ADM' } },
          select: { admissionNumber: true },
        });

        let maxNum = 0;
        for (const s of existingStudents) {
          const num = parseInt(s.admissionNumber.replace('ADM', ''), 10);
          if (!isNaN(num) && num > maxNum) {
            maxNum = num;
          }
        }
        admissionNumber = `ADM${String(maxNum + 1).padStart(3, '0')}`;
      }

      const existingAdm = await prisma.student.findFirst({
        where: { clientId, admissionNumber },
      });
      if (existingAdm) {
        res.status(409).json({ error: `Admission number ${admissionNumber} already in use in this school` });
        return;
      }

      const parsedDob = parseFlexibleDateString(dob) || new Date(dob);
      const parsedAdmissionDate = admissionDate ? (parseFlexibleDateString(admissionDate) || new Date(admissionDate)) : new Date();

      const student = await prisma.student.create({
        data: {
          clientId,
          admissionNumber,
          name: name.trim(),
          dob: parsedDob,
          gender: gender || 'Other',
          classId,
          parentName: parentName.trim(),
          parentContact: parentContact.trim(),
          parentEmail: parentEmail && parentEmail.trim().length > 0 ? parentEmail.trim() : null,
          admissionDate: parsedAdmissionDate,
          status: status || StudentStatus.ACTIVE,
        },
        include: {
          class: true,
        },
      });

      res.status(201).json({
        message: 'Student admitted successfully',
        student,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async updateStudent(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const cleanBody = sanitizeTenantInput(req.body);

      const existing = await prisma.student.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      const data: any = { ...cleanBody };
      if (data.dob) {
        data.dob = parseFlexibleDateString(data.dob) || new Date(data.dob);
      }
      if (data.admissionDate) {
        data.admissionDate = parseFlexibleDateString(data.admissionDate) || new Date(data.admissionDate);
      }
      if (data.parentEmail !== undefined) {
        data.parentEmail = data.parentEmail && data.parentEmail.trim().length > 0 ? data.parentEmail.trim() : null;
      }

      const updated = await prisma.student.update({
        where: { id },
        data,
        include: { class: true },
      });

      res.status(200).json({
        message: 'Student updated successfully',
        student: updated,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async deleteStudent(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      const existing = await prisma.student.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      // Clean up relations
      await prisma.attendance.deleteMany({ where: { studentId: id, clientId } });
      await prisma.mark.deleteMany({ where: { studentId: id, clientId } });
      await prisma.certificate.deleteMany({ where: { studentId: id, clientId } });
      await prisma.feePayment.deleteMany({ where: { studentId: id, clientId } });

      await prisma.student.delete({
        where: { id },
      });

      res.status(200).json({ message: 'Student deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
