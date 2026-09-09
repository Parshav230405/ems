import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import { execFile } from 'child_process';
import prisma from '../config/db';
import { calculateGrade } from './exams.controller';
import { getTenantId } from '../utils/tenant.util';
import { PdfService } from '../services/pdf.service';

export class ReportsController {
  public static async getSchoolSummary(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const [totalStudents, totalTeachers, totalClasses, activeStudents, inactiveStudents] =
        await Promise.all([
          prisma.student.count({ where: { clientId } }),
          prisma.teacher.count({ where: { clientId } }),
          prisma.class.count({ where: { clientId } }),
          prisma.student.count({ where: { clientId, status: 'ACTIVE' } }),
          prisma.student.count({ where: { clientId, status: 'INACTIVE' } }),
        ]);

      const feeSum = await prisma.feePayment.aggregate({
        where: { clientId },
        _sum: { amountPaid: true },
      });
      const totalFeesCollected = Number(feeSum._sum.amountPaid || 0);

      // Class-wise student distribution for this tenant
      const classes = await prisma.class.findMany({
        where: { clientId },
        include: {
          _count: { select: { students: true } },
        },
      });

      res.status(200).json({
        totalStudents,
        totalTeachers,
        totalClasses,
        activeStudents,
        inactiveStudents,
        totalFeesCollected,
        classDistribution: classes.map((c) => ({
          className: `${c.name}-${c.division}`,
          studentCount: c._count.students,
        })),
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getStudentReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { studentId } = req.params;

      const student = await prisma.student.findFirst({
        where: { id: studentId, clientId },
        include: {
          class: {
            include: {
              feeStructure: { where: { clientId } },
            },
          },
          attendance: { where: { clientId } },
          marks: {
            where: { clientId },
            include: {
              exam: {
                include: { subject: true },
              },
            },
          },
          feePayments: { where: { clientId } },
        },
      });

      if (!student) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      // Attendance summary
      const totalAttendance = student.attendance.length;
      const presentCount = student.attendance.filter((a) => a.status === 'PRESENT').length;
      const attendanceRate =
        totalAttendance > 0 ? Math.round((presentCount / totalAttendance) * 100) : 100;

      // Fees summary
      const totalFee = student.class.feeStructure.reduce(
        (sum, fs) => sum + Number(fs.amount),
        0
      );
      const totalPaid = student.feePayments.reduce(
        (sum, fp) => sum + Number(fp.amountPaid),
        0
      );
      const pendingFee = Math.max(0, totalFee - totalPaid);

      // Academic performance summary
      let totalMaxMarks = 0;
      let totalObtainedMarks = 0;
      const examResults = student.marks.map((m) => {
        const maxMarks = m.exam.maxMarks;
        const obtained = Number(m.marksObtained);
        totalMaxMarks += maxMarks;
        totalObtainedMarks += obtained;
        const percentage = maxMarks > 0 ? (obtained / maxMarks) * 100 : 0;
        return {
          examName: m.exam.name,
          subject: m.exam.subject.name,
          marksObtained: obtained,
          maxMarks,
          percentage: Number(percentage.toFixed(1)),
          grade: calculateGrade(percentage),
          isPassed: obtained >= m.exam.passMarks,
        };
      });

      const overallPercentage =
        totalMaxMarks > 0 ? (totalObtainedMarks / totalMaxMarks) * 100 : 0;
      const overallGrade = calculateGrade(overallPercentage);

      res.status(200).json({
        student: {
          id: student.id,
          name: student.name,
          admissionNumber: student.admissionNumber,
          dob: student.dob.toISOString().split('T')[0],
          gender: student.gender,
          class: `${student.class.name}-${student.class.division}`,
          parentName: student.parentName,
          parentContact: student.parentContact,
        },
        attendance: {
          totalDays: totalAttendance,
          presentDays: presentCount,
          percentage: attendanceRate,
        },
        fees: {
          totalFee,
          totalPaid,
          pendingFee,
        },
        academics: {
          totalMaxMarks,
          totalObtainedMarks,
          overallPercentage: Number(overallPercentage.toFixed(1)),
          overallGrade,
          exams: examResults,
        },
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async downloadStudentReportPdf(req: Request, res: Response): Promise<void> {
    try {
      const { studentId } = req.params;

      // Find student and their tenant
      const student = await prisma.student.findUnique({
        where: { id: studentId },
        include: {
          class: {
            include: {
              feeStructure: true,
            },
          },
          attendance: true,
          marks: {
            include: {
              exam: {
                include: { subject: true },
              },
            },
          },
          feePayments: true,
        },
      });

      if (!student) {
        res.status(404).json({ error: 'Student not found' });
        return;
      }

      const clientId = student.clientId;

      // Fetch School Settings for Branding
      const [schoolNameSetting, schoolAddressSetting, schoolPhoneSetting, principalSetting] =
        await Promise.all([
          prisma.setting.findFirst({ where: { clientId, key: 'school_name' } }),
          prisma.setting.findFirst({ where: { clientId, key: 'school_address' } }),
          prisma.setting.findFirst({ where: { clientId, key: 'school_phone' } }),
          prisma.setting.findFirst({ where: { clientId, key: 'principal_name' } }),
        ]);

      // Attendance summary
      const totalAttendance = student.attendance.length;
      const presentCount = student.attendance.filter((a) => a.status === 'PRESENT').length;
      const attendanceRate =
        totalAttendance > 0 ? Math.round((presentCount / totalAttendance) * 100) : 100;

      // Fees summary
      const totalFee = student.class.feeStructure.reduce(
        (sum, fs) => sum + Number(fs.amount),
        0
      );
      const totalPaid = student.feePayments.reduce(
        (sum, fp) => sum + Number(fp.amountPaid),
        0
      );
      const pendingFee = Math.max(0, totalFee - totalPaid);

      // Academic performance summary
      let totalMaxMarks = 0;
      let totalObtainedMarks = 0;
      const examResults = student.marks.map((m) => {
        const maxMarks = m.exam.maxMarks;
        const obtained = Number(m.marksObtained);
        totalMaxMarks += maxMarks;
        totalObtainedMarks += obtained;
        const percentage = maxMarks > 0 ? (obtained / maxMarks) * 100 : 0;
        return {
          examName: m.exam.name,
          subject: m.exam.subject.name,
          marksObtained: obtained,
          maxMarks,
          percentage: Number(percentage.toFixed(1)),
          grade: calculateGrade(percentage),
          isPassed: obtained >= m.exam.passMarks,
        };
      });

      const overallPercentage =
        totalMaxMarks > 0 ? (totalObtainedMarks / totalMaxMarks) * 100 : 0;
      const overallGrade = calculateGrade(overallPercentage);

      PdfService.generateStudentReportCardPdf(res, {
        schoolName: schoolNameSetting?.value || 'AURA EMS School',
        schoolAddress: schoolAddressSetting?.value || 'Institutional Campus',
        schoolPhone: schoolPhoneSetting?.value || '+91 98765 43210',
        studentName: student.name,
        admissionNumber: student.admissionNumber,
        className: student.class.name,
        division: student.class.division,
        dob: student.dob.toISOString().split('T')[0],
        gender: student.gender,
        parentName: student.parentName,
        parentContact: student.parentContact,
        attendance: {
          totalDays: totalAttendance,
          presentDays: presentCount,
          percentage: attendanceRate,
        },
        fees: {
          totalFee,
          totalPaid,
          pendingFee,
        },
        academics: {
          totalMaxMarks,
          totalObtainedMarks,
          overallPercentage: Number(overallPercentage.toFixed(1)),
          overallGrade,
          exams: examResults,
        },
        reportDate: new Date().toLocaleDateString('en-GB', {
          day: '2-digit',
          month: 'short',
          year: 'numeric',
        }),
        principalName: principalSetting?.value || 'Dr. S. K. Mukherjee',
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getAttendanceReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const [totalRecords, presentCount, absentCount, leaveCount] = await Promise.all([
        prisma.attendance.count({ where: { clientId } }),
        prisma.attendance.count({ where: { clientId, status: 'PRESENT' } }),
        prisma.attendance.count({ where: { clientId, status: 'ABSENT' } }),
        prisma.attendance.count({ where: { clientId, status: 'LEAVE' } }),
      ]);

      const overallPercentage = totalRecords > 0 ? Math.round((presentCount / totalRecords) * 100) : 100;

      const classes = await prisma.class.findMany({
        where: { clientId },
        include: {
          students: {
            where: { status: 'ACTIVE' },
            select: { id: true },
          },
        },
      });

      const classBreakdown = await Promise.all(
        classes.map(async (c) => {
          const studentIds = c.students.map((s) => s.id);
          const classTotal = await prisma.attendance.count({
            where: { clientId, studentId: { in: studentIds } },
          });
          const classPresent = await prisma.attendance.count({
            where: { clientId, studentId: { in: studentIds }, status: 'PRESENT' },
          });
          const pct = classTotal > 0 ? Math.round((classPresent / classTotal) * 100) : 100;
          return {
            classId: c.id,
            className: `${c.name}-${c.division}`,
            totalStudents: c.students.length,
            attendanceRate: pct,
          };
        })
      );

      res.status(200).json({
        totalRecords,
        presentCount,
        absentCount,
        leaveCount,
        overallPercentage,
        classBreakdown,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getFeeReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const feeStructures = await prisma.feeStructure.findMany({
        where: { clientId },
        include: { class: true },
      });

      let totalExpected = 0;
      const classBreakdown = [];

      for (const fs of feeStructures) {
        const studentCount = await prisma.student.count({
          where: { clientId, classId: fs.classId, status: 'ACTIVE' },
        });
        const classExpected = Number(fs.amount) * studentCount;
        totalExpected += classExpected;

        const classStudents = await prisma.student.findMany({
          where: { clientId, classId: fs.classId },
          select: { id: true },
        });
        const studentIds = classStudents.map((s) => s.id);

        const classPaidAgg = await prisma.feePayment.aggregate({
          where: { clientId, studentId: { in: studentIds } },
          _sum: { amountPaid: true },
        });
        const classCollected = Number(classPaidAgg._sum.amountPaid || 0);

        classBreakdown.push({
          className: `${fs.class.name}-${fs.class.division}`,
          title: fs.title,
          studentCount,
          expected: classExpected,
          collected: classCollected,
          pending: Math.max(0, classExpected - classCollected),
        });
      }

      const totalFeeSum = await prisma.feePayment.aggregate({
        where: { clientId },
        _sum: { amountPaid: true },
      });
      const totalCollected = Number(totalFeeSum._sum.amountPaid || 0);
      const totalPending = Math.max(0, totalExpected - totalCollected);
      const collectionRate = totalExpected > 0 ? Math.round((totalCollected / totalExpected) * 100) : 100;

      const payments = await prisma.feePayment.findMany({
        where: { clientId },
        select: { mode: true, amountPaid: true },
      });
      const modeDistribution: Record<string, number> = {};
      for (const p of payments) {
        modeDistribution[p.mode] = (modeDistribution[p.mode] || 0) + Number(p.amountPaid);
      }

      const recentTransactions = await prisma.feePayment.findMany({
        where: { clientId },
        take: 10,
        orderBy: { paymentDate: 'desc' },
        include: {
          student: {
            select: { name: true, admissionNumber: true, class: { select: { name: true, division: true } } },
          },
        },
      });

      res.status(200).json({
        totalExpected,
        totalCollected,
        totalPending,
        collectionRate,
        modeDistribution,
        classBreakdown,
        recentTransactions: recentTransactions.map((t) => ({
          receiptNo: t.receiptNo,
          studentName: t.student.name,
          admissionNumber: t.student.admissionNumber,
          className: `${t.student.class.name}-${t.student.class.division}`,
          amountPaid: Number(t.amountPaid),
          mode: t.mode,
          paymentDate: t.paymentDate.toISOString().split('T')[0],
        })),
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getResultReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const exams = await prisma.exam.findMany({
        where: { clientId },
        include: {
          subject: true,
          class: true,
          marks: {
            where: { clientId },
            include: { student: true },
          },
        },
      });

      let totalEvaluated = 0;
      let totalPassed = 0;
      let scoreSum = 0;

      const examAnalytics = exams.map((e) => {
        const studentMarks = e.marks;
        const count = studentMarks.length;
        const passCount = studentMarks.filter((m) => Number(m.marksObtained) >= e.passMarks).length;
        const avgMarks = count > 0 ? studentMarks.reduce((s, m) => s + Number(m.marksObtained), 0) / count : 0;
        const avgPercentage = e.maxMarks > 0 ? Number(((avgMarks / e.maxMarks) * 100).toFixed(1)) : 0;

        totalEvaluated += count;
        totalPassed += passCount;
        scoreSum += avgPercentage;

        return {
          examId: e.id,
          name: e.name,
          subject: e.subject.name,
          className: `${e.class.name}-${e.class.division}`,
          totalStudents: count,
          passCount,
          averagePercentage: avgPercentage,
          maxMarks: e.maxMarks,
        };
      });

      const overallPassRate = totalEvaluated > 0 ? Math.round((totalPassed / totalEvaluated) * 100) : 100;
      const overallAvg = exams.length > 0 ? Math.round(scoreSum / exams.length) : 0;

      const allMarks = await prisma.mark.findMany({
        where: { clientId },
        include: {
          student: { include: { class: true } },
          exam: true,
        },
      });

      const studentMap: Record<string, { name: string; admNo: string; className: string; totalObtained: number; totalMax: number }> = {};
      for (const m of allMarks) {
        if (!studentMap[m.studentId]) {
          studentMap[m.studentId] = {
            name: m.student.name,
            admNo: m.student.admissionNumber,
            className: `${m.student.class.name}-${m.student.class.division}`,
            totalObtained: 0,
            totalMax: 0,
          };
        }
        studentMap[m.studentId].totalObtained += Number(m.marksObtained);
        studentMap[m.studentId].totalMax += m.exam.maxMarks;
      }

      const topStudents = Object.values(studentMap)
        .filter((s) => s.totalMax > 0)
        .map((s) => ({
          name: s.name,
          admissionNumber: s.admNo,
          className: s.className,
          percentage: Number(((s.totalObtained / s.totalMax) * 100).toFixed(1)),
          grade: calculateGrade((s.totalObtained / s.totalMax) * 100),
        }))
        .sort((a, b) => b.percentage - a.percentage)
        .slice(0, 5);

      res.status(200).json({
        totalExams: exams.length,
        totalEvaluated,
        overallPassRate,
        overallAverage: overallAvg,
        examAnalytics,
        topStudents,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getClassReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const classes = await prisma.class.findMany({
        where: { clientId },
        include: {
          students: {
            where: { clientId, status: 'ACTIVE' },
            select: { gender: true },
          },
          feeStructure: {
            where: { clientId },
          },
        },
      });

      const details = classes.map((c) => {
        const maleCount = c.students.filter((s) => s.gender.toLowerCase() === 'male').length;
        const femaleCount = c.students.filter((s) => s.gender.toLowerCase() === 'female').length;
        const totalFeeAmount = c.feeStructure.reduce((sum, f) => sum + Number(f.amount), 0);

        return {
          id: c.id,
          className: `${c.name}-${c.division}`,
          academicYear: c.academicYear,
          enrolled: c.students.length,
          boys: maleCount,
          girls: femaleCount,
          annualFeePerStudent: totalFeeAmount,
        };
      });

      res.status(200).json({ classes: details });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async getTeacherReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);

      const teachers = await prisma.teacher.findMany({
        where: { clientId },
        include: {
          subjects: {
            where: { clientId },
            include: { class: true },
          },
        },
      });

      const details = teachers.map((t) => ({
        id: t.id,
        name: t.name,
        email: t.email,
        contact: t.contact,
        qualification: t.qualification,
        status: t.status,
        subjectCount: t.subjects.length,
        subjects: t.subjects.map((s) => `${s.name} (${s.class.name}-${s.class.division})`),
      }));

      res.status(200).json({
        totalTeachers: teachers.length,
        activeTeachers: teachers.filter((t) => t.status === 'Active').length,
        teachers: details,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async generateInternshipReport(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const {
        studentId,
        projectTitle,
        internshipTitle,
        companyName,
        companyAddress,
        companyGuide,
        facultyGuide,
        universityName,
        instituteName,
        departmentName,
        courseCode,
        duration,
        abstract,
        technologies,
      } = req.body;

      const student = await prisma.student.findFirst({
        where: { id: studentId, clientId },
        include: { class: true },
      });

      if (!student) {
        res.status(404).json({ error: 'Student not found in this school tenant' });
        return;
      }

      const timestamp = Date.now();
      const fileName = `Internship_Report_${student.admissionNumber}_${timestamp}.docx`;
      const outputDir = path.resolve(__dirname, '../../uploads/internship_reports');
      fs.mkdirSync(outputDir, { recursive: true });
      const outputPath = path.join(outputDir, fileName);

      const config = {
        studentName: student.name,
        enrolmentNo: student.admissionNumber,
        projectTitle,
        internshipTitle: internshipTitle || 'Full-Stack Web Development',
        companyName: companyName || 'Vanshee Infotech',
        companyAddress: companyAddress || 'B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India',
        companyGuide: companyGuide || 'Bhavi Kansara (CEO)',
        facultyGuide: facultyGuide || 'Internal Faculty Guide',
        universityName: universityName || 'INDUS UNIVERSITY',
        instituteName: instituteName || 'INSTITUTE OF TECHNOLOGY AND ENGINEERING',
        departmentName: departmentName || 'COMPUTER SCIENCE ENGINEERING',
        courseCode: courseCode || 'CE0318 / CE0523 / CE0726',
        duration: duration || '15 Days / 65+ Hours',
        abstract: abstract || '',
        technologies: technologies || 'Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM, JWT, PDFKit',
        outputPath,
      };

      const tempConfigPath = path.join(outputDir, `config_${timestamp}.json`);
      fs.writeFileSync(tempConfigPath, JSON.stringify(config, null, 2), 'utf-8');

      const scriptPath = path.resolve(__dirname, '../scripts/generate_internship_report.py');

      execFile('python', [scriptPath, tempConfigPath], (error, stdout, stderr) => {
        try {
          fs.unlinkSync(tempConfigPath);
        } catch (_) {}

        if (error) {
          console.error('Python docx generator error:', stderr || error);
          res.status(500).json({ error: 'Failed to generate internship report document' });
          return;
        }

        res.status(201).json({
          message: 'Internship project report generated successfully',
          fileName,
          downloadUrl: `/api/reports/internship/${fileName}/download`,
          student: {
            id: student.id,
            name: student.name,
            admissionNumber: student.admissionNumber,
            class: student.class ? `${student.class.name}-${student.class.division}` : '',
          },
        });
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async downloadInternshipReport(req: Request, res: Response): Promise<void> {
    try {
      const { fileName } = req.params;
      const sanitized = path.basename(fileName);
      const filePath = path.resolve(__dirname, '../../uploads/internship_reports', sanitized);

      if (!fs.existsSync(filePath)) {
        res.status(404).json({ error: 'Internship report document not found' });
        return;
      }

      res.setHeader(
        'Content-Type',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      );
      res.setHeader('Content-Disposition', `attachment; filename="${sanitized}"`);
      fs.createReadStream(filePath).pipe(res);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}


