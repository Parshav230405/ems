import { Request, Response } from 'express';
import prisma from '../config/db';
import { PdfService } from '../services/pdf.service';
import { PaymentMode } from '@prisma/client';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class FeesController {
  public static async listFeeStructures(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { academicYear, classId } = req.query;
      const where: any = { clientId };
      if (academicYear) where.academicYear = academicYear as string;
      if (classId) where.classId = classId as string;

      const structures = await prisma.feeStructure.findMany({
        where,
        orderBy: { dueDate: 'asc' },
        include: {
          class: { select: { id: true, name: true, division: true } },
        },
      });

      res.status(200).json({ data: structures });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createFeeStructure(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { classId, academicYear, title, amount, dueDate } = cleanBody;

      const feeStructure = await prisma.feeStructure.create({
        data: {
          clientId,
          classId,
          academicYear,
          title,
          amount,
          dueDate: new Date(dueDate),
        },
        include: { class: true },
      });

      res.status(201).json({ message: 'Fee structure created successfully', feeStructure });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async recordPayment(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { studentId, amountPaid, paymentDate, mode, notes } = cleanBody;
      let { receiptNo } = cleanBody;

      if (!receiptNo) {
        const count = await prisma.feePayment.count({ where: { clientId } });
        receiptNo = `REC-${1001 + count}`;
      }

      // Verify student belongs to this tenant
      const student = await prisma.student.findFirst({
        where: { id: studentId, clientId },
      });
      if (!student) {
        res.status(404).json({ error: 'Student not found in your school' });
        return;
      }

      const payment = await prisma.feePayment.create({
        data: {
          clientId,
          studentId,
          amountPaid,
          paymentDate: paymentDate ? new Date(paymentDate) : new Date(),
          mode: mode || PaymentMode.CASH,
          receiptNo,
          notes: notes || null,
          receivedBy: req.user?.name || 'Admin',
        },
        include: {
          student: {
            include: { class: true },
          },
        },
      });

      res.status(201).json({
        message: 'Payment recorded successfully',
        payment,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getStudentFeeStatus(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { studentId } = req.params;

      const student = await prisma.student.findFirst({
        where: { id: studentId, clientId },
        include: {
          class: {
            include: {
              feeStructure: {
                where: { clientId },
              },
            },
          },
          feePayments: {
            where: { clientId },
            orderBy: { paymentDate: 'desc' },
          },
        },
      });

      if (!student) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

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
        student: {
          id: student.id,
          name: student.name,
          admissionNumber: student.admissionNumber,
          class: `${student.class.name}-${student.class.division}`,
        },
        totalFee,
        totalPaid,
        pendingFee,
        payments: student.feePayments,
        structures: student.class.feeStructure,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async downloadReceipt(req: Request, res: Response): Promise<void> {
    try {
      const { receiptNo } = req.params;

      const payment = await prisma.feePayment.findFirst({
        where: { receiptNo },
        include: {
          student: {
            include: {
              class: {
                include: {
                  feeStructure: true,
                },
              },
              feePayments: true,
            },
          },
        },
      });

      if (!payment) {
        res.status(404).json({ error: 'Receipt not found' });
        return;
      }

      const schoolNameSetting = await prisma.setting.findFirst({
        where: { clientId: payment.clientId, key: 'school_name' },
      });
      const schoolAddressSetting = await prisma.setting.findFirst({
        where: { clientId: payment.clientId, key: 'school_address' },
      });
      const schoolPhoneSetting = await prisma.setting.findFirst({
        where: { clientId: payment.clientId, key: 'school_phone' },
      });

      const totalFee = payment.student.class.feeStructure.reduce(
        (sum, fs) => sum + Number(fs.amount),
        0
      );
      const totalPaid = payment.student.feePayments.reduce(
        (sum, fp) => sum + Number(fp.amountPaid),
        0
      );
      const pendingFee = Math.max(0, totalFee - totalPaid);

      PdfService.generateFeeReceiptPdf(res, {
        schoolName: schoolNameSetting?.value || 'AURA EMS School',
        schoolAddress: schoolAddressSetting?.value || 'Campus Address',
        schoolPhone: schoolPhoneSetting?.value || '+91 98765 43210',
        receiptNo: payment.receiptNo,
        paymentDate: payment.paymentDate.toISOString().split('T')[0],
        studentName: payment.student.name,
        admissionNumber: payment.student.admissionNumber,
        className: payment.student.class.name,
        division: payment.student.class.division,
        amountPaid: Number(payment.amountPaid),
        paymentMode: payment.mode,
        notes: payment.notes || 'Tuition Fee Installment',
        receivedBy: payment.receivedBy || 'Accounts Officer',
        totalFee,
        totalPaidSoFar: totalPaid,
        pendingFee,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
