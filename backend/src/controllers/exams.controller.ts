import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export function calculateGrade(percentage: number): string {
  if (percentage >= 90) return 'A+';
  if (percentage >= 80) return 'A';
  if (percentage >= 70) return 'B+';
  if (percentage >= 60) return 'B';
  if (percentage >= 50) return 'C';
  if (percentage >= 35) return 'D';
  return 'F';
}

export class ExamsController {
  public static async listExams(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const classId = req.query.classId as string;
      const where: any = { clientId };
      if (classId) where.classId = classId;

      const exams = await prisma.exam.findMany({
        where,
        orderBy: { date: 'desc' },
        include: {
          class: { select: { id: true, name: true, division: true } },
          subject: { select: { id: true, name: true, code: true } },
          _count: { select: { marks: true } },
        },
      });

      res.status(200).json({ data: exams });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createExam(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { name, classId, subjectId, date, maxMarks, passMarks } = cleanBody;

      const exam = await prisma.exam.create({
        data: {
          clientId,
          name,
          classId,
          subjectId,
          date: new Date(date),
          maxMarks: maxMarks || 100,
          passMarks: passMarks || 35,
        },
        include: {
          class: true,
          subject: true,
        },
      });

      res.status(201).json({ message: 'Exam created successfully', exam });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getExamMarks(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { examId } = req.params;

      const exam = await prisma.exam.findFirst({
        where: { id: examId, clientId },
        include: {
          class: true,
          subject: true,
        },
      });

      if (!exam) {
        res.status(404).json({ error: 'Exam not found' });
        return;
      }

      // Fetch all students in this class for this tenant
      const students = await prisma.student.findMany({
        where: { clientId, classId: exam.classId, status: 'ACTIVE' },
        orderBy: { admissionNumber: 'asc' },
      });

      // Fetch existing marks
      const marks = await prisma.mark.findMany({
        where: { clientId, examId },
      });

      const marksMap = new Map<string, number>();
      marks.forEach((m) => {
        marksMap.set(m.studentId, Number(m.marksObtained));
      });

      const studentRows = students.map((s, index) => {
        const marksObtained = marksMap.has(s.id) ? marksMap.get(s.id)! : 0;
        const percentage = exam.maxMarks > 0 ? (marksObtained / exam.maxMarks) * 100 : 0;
        const grade = calculateGrade(percentage);
        const isPassed = marksObtained >= exam.passMarks;

        return {
          rollNo: index + 1,
          studentId: s.id,
          studentName: s.name,
          admissionNumber: s.admissionNumber,
          marksObtained,
          isEntered: marksMap.has(s.id),
          percentage: Number(percentage.toFixed(1)),
          grade,
          isPassed,
        };
      });

      res.status(200).json({
        exam,
        students: studentRows,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async saveExamMarks(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { examId, marks } = req.body;

      const exam = await prisma.exam.findFirst({ where: { id: examId, clientId } });
      if (!exam) {
        res.status(404).json({ error: 'Exam not found' });
        return;
      }

      await prisma.$transaction(
        marks.map((m: { studentId: string; marksObtained: number }) =>
          prisma.mark.upsert({
            where: {
              clientId_examId_studentId: {
                clientId,
                examId,
                studentId: m.studentId,
              },
            },
            update: {
              marksObtained: m.marksObtained,
            },
            create: {
              clientId,
              examId,
              studentId: m.studentId,
              marksObtained: m.marksObtained,
            },
          })
        )
      );

      res.status(200).json({ message: `Marks updated for ${marks.length} students` });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
