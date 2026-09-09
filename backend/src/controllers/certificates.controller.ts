import { Request, Response } from 'express';
import prisma from '../config/db';
import { PdfService } from '../services/pdf.service';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class CertificatesController {
  public static async listCertificates(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const certificates = await prisma.certificate.findMany({
        where: { clientId },
        orderBy: { issuedDate: 'desc' },
        include: {
          student: {
            include: {
              class: { select: { name: true, division: true } },
            },
          },
          issuer: {
            select: { id: true, name: true, email: true },
          },
        },
      });

      res.status(200).json({ data: certificates });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async generateCertificate(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { studentId, type, title, body, templateId } = cleanBody;
      const issuerId = req.user?.id;

      if (!issuerId) {
        res.status(401).json({ error: 'Issuer authentication required' });
        return;
      }

      const student = await prisma.student.findFirst({
        where: { id: studentId, clientId },
        include: { class: true },
      });

      if (!student) {
        res.status(404).json({ error: 'Student not found in your school' });
        return;
      }

      // Generate unique certificate number: CERT-YYYY-XXXX
      const year = new Date().getFullYear();
      const count = await prisma.certificate.count({ where: { clientId } });
      const certificateNo = `CERT-${year}-${String(1001 + count).padStart(4, '0')}`;

      // Create audit log record in database
      const certificate = await prisma.certificate.create({
        data: {
          clientId,
          studentId: student.id,
          type: type || 'Achievement',
          title: title || 'CERTIFICATE OF ACHIEVEMENT',
          body,
          issuedBy: issuerId,
          templateId: templateId || 'institutional_letterhead_v1',
          certificateNo,
          pdfUrl: `/api/certificates/${certificateNo}/download`,
        },
      });

      res.status(201).json({
        message: 'Certificate generated and logged successfully',
        certificate,
        downloadUrl: `/api/certificates/${certificateNo}/download`,
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async downloadCertificate(req: Request, res: Response): Promise<void> {
    try {
      const { certificateNo } = req.params;

      const cert = await prisma.certificate.findFirst({
        where: { certificateNo },
        include: {
          student: {
            include: { class: true },
          },
          issuer: true,
        },
      });

      if (!cert) {
        res.status(404).json({ error: 'Certificate not found' });
        return;
      }

      const schoolNameSetting = await prisma.setting.findFirst({ where: { clientId: cert.clientId, key: 'school_name' } });
      const schoolTaglineSetting = await prisma.setting.findFirst({ where: { clientId: cert.clientId, key: 'school_tagline' } });
      const principalSetting = await prisma.setting.findFirst({ where: { clientId: cert.clientId, key: 'principal_name' } });

      PdfService.generateCertificatePdf(res, {
        schoolName: schoolNameSetting?.value || 'AURA EMS School',
        schoolTagline: schoolTaglineSetting?.value || 'Excellence in Education',
        certificateTitle: cert.title,
        certificateNo: cert.certificateNo,
        studentName: cert.student.name,
        admissionNumber: cert.student.admissionNumber,
        className: cert.student.class.name,
        division: cert.student.class.division,
        body: cert.body,
        issueDate: cert.issuedDate.toISOString().split('T')[0],
        principalName: principalSetting?.value || 'Principal',
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
