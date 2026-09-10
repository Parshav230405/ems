import PDFDocument from 'pdfkit';
import { Response } from 'express';

export class PdfService {
  /**
   * Generates a printable, letterhead-styled A4 Certificate matching Section 7 spec
   */
  public static generateCertificatePdf(
    res: Response,
    data: {
      schoolName: string;
      schoolTagline: string;
      certificateTitle: string;
      certificateNo: string;
      studentName: string;
      admissionNumber: string;
      className: string;
      division: string;
      body: string;
      issueDate: string;
      principalName: string;
    }
  ): void {
    const doc = new PDFDocument({
      size: 'A4',
      layout: 'landscape',
      margin: 40,
    });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=Certificate_${data.certificateNo}.pdf`
    );

    doc.pipe(res);

    const width = doc.page.width;
    const height = doc.page.height;

    // Outer Decorative Border
    doc.lineWidth(4).strokeColor('#1E3A8A').rect(25, 25, width - 50, height - 50).stroke();
    doc.lineWidth(1).strokeColor('#D97706').rect(32, 32, width - 64, height - 64).stroke();

    // Corner Ornaments
    const cornerSize = 20;
    doc.lineWidth(2).strokeColor('#1E3A8A');
    doc.polygon([36, 36], [36 + cornerSize, 36], [36, 36 + cornerSize]).fillAndStroke('#1E3A8A', '#1E3A8A');
    doc.polygon([width - 36, 36], [width - 36 - cornerSize, 36], [width - 36, 36 + cornerSize]).fillAndStroke('#1E3A8A', '#1E3A8A');
    doc.polygon([36, height - 36], [36 + cornerSize, height - 36], [36, height - 36 - cornerSize]).fillAndStroke('#1E3A8A', '#1E3A8A');
    doc.polygon([width - 36, height - 36], [width - 36 - cornerSize, height - 36], [width - 36, height - 36 - cornerSize]).fillAndStroke('#1E3A8A', '#1E3A8A');

    // Header: School Name & Tagline
    doc.moveDown(1.5);
    doc.font('Helvetica-Bold').fontSize(26).fillColor('#1E3A8A').text(data.schoolName.toUpperCase(), { align: 'center' });
    if (data.schoolTagline) {
      doc.font('Helvetica-Oblique').fontSize(11).fillColor('#4B5563').text(data.schoolTagline, { align: 'center' });
    }

    doc.moveDown(1);
    doc.font('Helvetica-Bold').fontSize(22).fillColor('#B45309').text(data.certificateTitle.toUpperCase(), { align: 'center' });

    // Decorative underline
    const lineY = doc.y + 4;
    doc.moveTo(width / 2 - 120, lineY).lineTo(width / 2 + 120, lineY).lineWidth(2).strokeColor('#B45309').stroke();

    // Issue Context Line
    doc.moveDown(1.5);
    doc.font('Helvetica').fontSize(13).fillColor('#374151').text('This is to certify that', { align: 'center' });

    doc.moveDown(0.4);
    doc.font('Helvetica-Bold').fontSize(20).fillColor('#111827').text(data.studentName, { align: 'center' });

    doc.moveDown(0.3);
    doc.font('Helvetica').fontSize(12).fillColor('#4B5563').text(
      `bearing Admission Number ${data.admissionNumber}, of Class ${data.className} (Division ${data.division})`,
      { align: 'center' }
    );

    // Body Paragraphs
    doc.moveDown(1.2);
    doc.font('Helvetica').fontSize(12).fillColor('#1F2937').text(data.body, {
      align: 'center',
      lineGap: 4,
      indent: 40,
    });

    // Footer Block: Certificate No, Date, and Principal Signature
    const footerY = height - 110;
    doc.fontSize(10).fillColor('#6B7280');
    doc.text(`Certificate No: ${data.certificateNo}`, 60, footerY);
    doc.text(`Date of Issue: ${data.issueDate}`, 60, footerY + 16);

    // Right-aligned Signature Line
    doc.moveTo(width - 240, footerY + 10).lineTo(width - 60, footerY + 10).lineWidth(1).strokeColor('#4B5563').stroke();
    doc.font('Helvetica-Bold').fontSize(11).fillColor('#111827').text(data.principalName, width - 240, footerY + 16, { width: 180, align: 'center' });
    doc.font('Helvetica').fontSize(10).fillColor('#6B7280').text('Principal / Authorized Signatory', width - 240, footerY + 30, { width: 180, align: 'center' });

    doc.end();
  }

  /**
   * Generates a printable A4 Fee Payment Receipt
   */
  public static generateFeeReceiptPdf(
    res: Response,
    data: {
      schoolName: string;
      schoolAddress: string;
      schoolPhone: string;
      receiptNo: string;
      paymentDate: string;
      studentName: string;
      admissionNumber: string;
      className: string;
      division: string;
      amountPaid: number;
      paymentMode: string;
      notes: string;
      receivedBy: string;
      totalFee: number;
      totalPaidSoFar: number;
      pendingFee: number;
    }
  ): void {
    const doc = new PDFDocument({ size: 'A4', margin: 40 });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=Receipt_${data.receiptNo}.pdf`
    );

    doc.pipe(res);
    const width = doc.page.width;

    // Header Border
    doc.rect(30, 30, width - 60, 780).strokeColor('#E5E7EB').stroke();

    // School Info
    doc.font('Helvetica-Bold').fontSize(18).fillColor('#1E3A8A').text(data.schoolName, { align: 'center' });
    doc.font('Helvetica').fontSize(10).fillColor('#6B7280').text(data.schoolAddress, { align: 'center' });
    doc.text(`Phone: ${data.schoolPhone}`, { align: 'center' });
    doc.moveDown(0.8);

    doc.font('Helvetica-Bold').fontSize(14).fillColor('#111827').text('FEE PAYMENT RECEIPT', { align: 'center' });
    doc.moveTo(40, doc.y + 4).lineTo(width - 40, doc.y + 4).strokeColor('#1E3A8A').lineWidth(1.5).stroke();
    doc.moveDown(1.5);

    // Meta details row
    const metaY = doc.y;
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#374151');
    doc.text(`Receipt No: ${data.receiptNo}`, 50, metaY);
    doc.text(`Date: ${data.paymentDate}`, width - 200, metaY);

    doc.moveDown(1.5);
    // Student info box
    const boxY = doc.y;
    doc.rect(50, boxY, width - 100, 65).fillAndStroke('#F9FAFB', '#E5E7EB');
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#1F2937');
    doc.text('Student Name:', 65, boxY + 12);
    doc.font('Helvetica').text(data.studentName, 160, boxY + 12);

    doc.font('Helvetica-Bold').text('Admission No:', 65, boxY + 36);
    doc.font('Helvetica').text(data.admissionNumber, 160, boxY + 36);

    doc.font('Helvetica-Bold').text('Class / Div:', 330, boxY + 12);
    doc.font('Helvetica').text(`${data.className} - ${data.division}`, 410, boxY + 12);

    doc.font('Helvetica-Bold').text('Payment Mode:', 330, boxY + 36);
    doc.font('Helvetica').text(data.paymentMode, 410, boxY + 36);

    doc.moveDown(4.5);

    // Payment breakdown table
    const tableTop = doc.y;
    doc.rect(50, tableTop, width - 100, 25).fill('#1E3A8A');
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#FFFFFF');
    doc.text('Description', 65, tableTop + 7);
    doc.text('Amount (INR)', width - 160, tableTop + 7);

    let rowY = tableTop + 30;
    doc.font('Helvetica').fontSize(10).fillColor('#111827');
    doc.text(data.notes || 'Tuition Fee Installment', 65, rowY);
    doc.text(`₹ ${data.amountPaid.toLocaleString('en-IN')}`, width - 160, rowY);

    rowY += 25;
    doc.moveTo(50, rowY).lineTo(width - 50, rowY).strokeColor('#E5E7EB').stroke();
    rowY += 10;

    doc.font('Helvetica-Bold').text('Total Paid in this Receipt:', 65, rowY);
    doc.text(`₹ ${data.amountPaid.toLocaleString('en-IN')}`, width - 160, rowY);

    rowY += 35;
    // Summary box
    doc.rect(50, rowY, width - 100, 70).fillAndStroke('#EFF6FF', '#BFDBFE');
    doc.font('Helvetica-Bold').fillColor('#1E3A8A');
    doc.text(`Total Annual Class Fee: ₹ ${data.totalFee.toLocaleString('en-IN')}`, 70, rowY + 12);
    doc.text(`Cumulative Amount Paid: ₹ ${data.totalPaidSoFar.toLocaleString('en-IN')}`, 70, rowY + 30);
    doc.text(`Remaining Balance Pending: ₹ ${data.pendingFee.toLocaleString('en-IN')}`, 70, rowY + 48);

    // Signatures
    const sigY = 700;
    doc.fontSize(10).fillColor('#4B5563');
    doc.text(`Cashier / Received By: ${data.receivedBy || 'Accounts Officer'}`, 65, sigY);
    doc.moveTo(width - 220, sigY).lineTo(width - 60, sigY).strokeColor('#9CA3AF').stroke();
    doc.text('Authorized Signature & Stamp', width - 220, sigY + 6, { width: 160, align: 'center' });

    doc.end();
  }

  /**
   * Generates a formal A4 Portrait Student Academic Performance Report Card
   */
  public static generateStudentReportCardPdf(
    res: Response,
    data: {
      schoolName: string;
      schoolAddress: string;
      schoolPhone: string;
      studentName: string;
      admissionNumber: string;
      className: string;
      division: string;
      dob: string;
      gender: string;
      parentName: string;
      parentContact: string;
      attendance: {
        totalDays: number;
        presentDays: number;
        percentage: number;
      };
      fees: {
        totalFee: number;
        totalPaid: number;
        pendingFee: number;
      };
      academics: {
        totalMaxMarks: number;
        totalObtainedMarks: number;
        overallPercentage: number;
        overallGrade: string;
        exams: Array<{
          examName: string;
          subject: string;
          marksObtained: number;
          maxMarks: number;
          percentage: number;
          grade: string;
          isPassed: boolean;
        }>;
      };
      reportDate: string;
      principalName: string;
    }
  ): void {
    const doc = new PDFDocument({ size: 'A4', margin: 36 });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=ReportCard_${data.admissionNumber}.pdf`
    );

    doc.pipe(res);
    const width = doc.page.width;

    // Outer Decorative Double Border
    doc.lineWidth(2).strokeColor('#1E3A8A').rect(25, 25, width - 50, 792).stroke();
    doc.lineWidth(0.75).strokeColor('#D97706').rect(29, 29, width - 58, 784).stroke();

    // School Header
    doc.moveDown(0.6);
    doc.font('Helvetica-Bold').fontSize(20).fillColor('#1E3A8A').text(data.schoolName.toUpperCase(), { align: 'center' });
    if (data.schoolAddress) {
      doc.font('Helvetica').fontSize(9).fillColor('#4B5563').text(data.schoolAddress, { align: 'center' });
    }
    if (data.schoolPhone) {
      doc.fontSize(9).fillColor('#6B7280').text(`Contact: ${data.schoolPhone} • Academic Session 2025-2026`, { align: 'center' });
    }
    doc.moveDown(0.6);

    // Title Banner
    doc.rect(40, doc.y, width - 80, 24).fill('#1E3A8A');
    doc.font('Helvetica-Bold').fontSize(12).fillColor('#FFFFFF').text('OFFICIAL STUDENT ACADEMIC REPORT CARD', 40, doc.y + 6, {
      width: width - 80,
      align: 'center',
    });
    doc.moveDown(1.5);

    // Student Profile Box
    const profileY = doc.y;
    doc.rect(40, profileY, width - 80, 84).fillAndStroke('#F8FAFC', '#E2E8F0');
    doc.font('Helvetica-Bold').fontSize(9.5).fillColor('#1E293B');

    // Left column
    doc.text('Student Name:', 55, profileY + 12);
    doc.font('Helvetica').text(data.studentName, 155, profileY + 12);
    doc.font('Helvetica-Bold').text('Admission No:', 55, profileY + 30);
    doc.font('Helvetica').text(data.admissionNumber, 155, profileY + 30);
    doc.font('Helvetica-Bold').text('Class & Division:', 55, profileY + 48);
    doc.font('Helvetica').text(`Class ${data.className} - ${data.division}`, 155, profileY + 48);
    doc.font('Helvetica-Bold').text('Date of Birth:', 55, profileY + 66);
    doc.font('Helvetica').text(data.dob, 155, profileY + 66);

    // Right column
    doc.font('Helvetica-Bold').text('Gender:', 320, profileY + 12);
    doc.font('Helvetica').text(data.gender, 410, profileY + 12);
    doc.font('Helvetica-Bold').text('Parent / Guardian:', 320, profileY + 30);
    doc.font('Helvetica').text(data.parentName, 410, profileY + 30);
    doc.font('Helvetica-Bold').text('Parent Contact:', 320, profileY + 48);
    doc.font('Helvetica').text(data.parentContact, 410, profileY + 48);
    doc.font('Helvetica-Bold').text('Report Date:', 320, profileY + 66);
    doc.font('Helvetica').text(data.reportDate, 410, profileY + 66);

    doc.moveDown(6.2);

    // Quick Metrics Highlights Row (Attendance & Overall Grade)
    const metricY = doc.y;
    const cardWidth = (width - 80 - 24) / 3;

    // Card 1: Attendance
    doc.rect(40, metricY, cardWidth, 46).fillAndStroke('#EFF6FF', '#BFDBFE');
    doc.font('Helvetica').fontSize(8.5).fillColor('#1E40AF').text('ATTENDANCE RECORD', 45, metricY + 8, { width: cardWidth - 10, align: 'center' });
    doc.font('Helvetica-Bold').fontSize(13).fillColor('#1E3A8A').text(`${data.attendance.percentage}% (${data.attendance.presentDays}/${data.attendance.totalDays} Days)`, 45, metricY + 24, { width: cardWidth - 10, align: 'center' });

    // Card 2: Overall Academic Score
    doc.rect(40 + cardWidth + 12, metricY, cardWidth, 46).fillAndStroke('#ECFDF5', '#A7F3D0');
    doc.font('Helvetica').fontSize(8.5).fillColor('#065F46').text('OVERALL ACADEMIC SCORE', 40 + cardWidth + 12, metricY + 8, { width: cardWidth, align: 'center' });
    doc.font('Helvetica-Bold').fontSize(13).fillColor('#047857').text(`${data.academics.overallPercentage}% (Grade ${data.academics.overallGrade})`, 40 + cardWidth + 12, metricY + 24, { width: cardWidth, align: 'center' });

    // Card 3: Fee Status
    doc.rect(40 + (cardWidth + 12) * 2, metricY, cardWidth, 46).fillAndStroke('#FEF3C7', '#FDE68A');
    doc.font('Helvetica').fontSize(8.5).fillColor('#92400E').text('ANNUAL FEE BALANCE', 40 + (cardWidth + 12) * 2, metricY + 8, { width: cardWidth, align: 'center' });
    doc.font('Helvetica-Bold').fontSize(13).fillColor(data.fees.pendingFee > 0 ? '#B45309' : '#047857').text(data.fees.pendingFee > 0 ? `₹ ${data.fees.pendingFee} Due` : 'Clear (No Arrears)', 40 + (cardWidth + 12) * 2, metricY + 24, { width: cardWidth, align: 'center' });

    doc.moveDown(4.2);

    // Subject Performance Marks Table
    doc.font('Helvetica-Bold').fontSize(11).fillColor('#111827').text('EXAMINATION & SUBJECT-WISE PERFORMANCE', 40, doc.y);
    doc.moveDown(0.4);

    const tableTop = doc.y;
    doc.rect(40, tableTop, width - 80, 22).fill('#1E3A8A');
    doc.font('Helvetica-Bold').fontSize(9).fillColor('#FFFFFF');
    doc.text('Exam Name', 50, tableTop + 6);
    doc.text('Subject', 160, tableTop + 6);
    doc.text('Max Marks', 280, tableTop + 6);
    doc.text('Obtained', 355, tableTop + 6);
    doc.text('Percentage', 420, tableTop + 6);
    doc.text('Grade', 485, tableTop + 6);
    doc.text('Status', 525, tableTop + 6);

    let rowY = tableTop + 24;

    if (data.academics.exams && data.academics.exams.length > 0) {
      data.academics.exams.forEach((e, idx) => {
        const isEven = idx % 2 === 0;
        if (isEven) {
          doc.rect(40, rowY - 2, width - 80, 20).fill('#F8FAFC');
        }
        doc.font('Helvetica').fontSize(8.5).fillColor('#1F2937');
        doc.text(e.examName, 50, rowY + 3);
        doc.text(e.subject, 160, rowY + 3);
        doc.text(String(e.maxMarks), 280, rowY + 3);
        doc.font('Helvetica-Bold').text(String(e.marksObtained), 355, rowY + 3);
        doc.font('Helvetica').text(`${e.percentage}%`, 420, rowY + 3);
        doc.font('Helvetica-Bold').fillColor('#1E3A8A').text(e.grade, 485, rowY + 3);
        doc.fillColor(e.isPassed ? '#16A34A' : '#DC2626').text(e.isPassed ? 'PASS' : 'FAIL', 525, rowY + 3);

        rowY += 20;
        doc.moveTo(40, rowY - 2).lineTo(width - 40, rowY - 2).lineWidth(0.5).strokeColor('#E2E8F0').stroke();
      });
    } else {
      doc.font('Helvetica').fontSize(9).fillColor('#6B7280').text('No recorded examination marks available for this academic year.', 50, rowY + 6);
      rowY += 26;
    }

    // Cumulative Total Row
    doc.rect(40, rowY, width - 80, 24).fillAndStroke('#EFF6FF', '#BFDBFE');
    doc.font('Helvetica-Bold').fontSize(9.5).fillColor('#1E3A8A');
    doc.text('CUMULATIVE TOTAL / RESULT:', 50, rowY + 7);
    doc.text(`Obtained: ${data.academics.totalObtainedMarks} / ${data.academics.totalMaxMarks}`, 280, rowY + 7);
    doc.text(`Average: ${data.academics.overallPercentage}%`, 420, rowY + 7);
    doc.text(`Grade: ${data.academics.overallGrade}`, 485, rowY + 7);
    const hasPassedAll = data.academics.exams.every((e) => e.isPassed);
    doc.fillColor(hasPassedAll ? '#16A34A' : '#DC2626').text(hasPassedAll ? 'PROMOTED' : 'NEEDS IMPROVEMENT', 525, rowY + 7);

    // Grading Scale Legend
    const legendY = 670;
    doc.rect(40, legendY, width - 80, 36).fillAndStroke('#F9FAFB', '#E5E7EB');
    doc.font('Helvetica-Bold').fontSize(8).fillColor('#374151').text('GRADING SCALE & REMARKS:', 50, legendY + 6);
    doc.font('Helvetica').fontSize(7.5).fillColor('#6B7280').text(
      'A+ (90-100% Outstanding) | A (80-89% Excellent) | B+ (70-79% Very Good) | B (60-69% Good) | C (50-59% Satisfactory) | D (40-49% Pass) | F (<40% Fail)',
      50,
      legendY + 18
    );

    // Signatures Block
    const signY = 745;
    doc.moveTo(60, signY).lineTo(220, signY).lineWidth(1).strokeColor('#94A3B8').stroke();
    doc.font('Helvetica').fontSize(9).fillColor('#475569').text('Class Teacher Signature', 60, signY + 6, { width: 160, align: 'center' });

    doc.moveTo(width - 220, signY).lineTo(width - 60, signY).lineWidth(1).strokeColor('#94A3B8').stroke();
    doc.font('Helvetica-Bold').fontSize(9.5).fillColor('#0F172A').text(data.principalName, width - 220, signY + 6, { width: 160, align: 'center' });
    doc.font('Helvetica').fontSize(8.5).fillColor('#64748B').text('Principal / Headmaster Stamp', width - 220, signY + 18, { width: 160, align: 'center' });

    doc.end();
  }

  /**
   * Generates a landscape A4 Timetable PDF for a specific class
   */
  public static generateTimetablePdf(
    res: Response,
    data: {
      schoolName: string;
      schoolTagline: string;
      className: string;
      academicYear: string;
      days: string[];
      periods: Array<{
        period: number;
        time: string;
      }>;
      entries: Array<{
        dayOfWeek: string;
        period: number;
        subjectName: string;
        teacherName?: string;
        startTime?: string;
        endTime?: string;
      }>;
    }
  ): void {
    const doc = new PDFDocument({
      size: 'A4',
      layout: 'landscape',
      margin: 30,
    });

    const safeFilename = `Timetable_${data.className.replace(/[^a-zA-Z0-9_-]/g, '_')}.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${safeFilename}"`);

    doc.pipe(res);

    const width = doc.page.width;
    const height = doc.page.height;
    const margin = 30;
    const contentWidth = width - margin * 2;

    // Outer Border
    doc.lineWidth(2).strokeColor('#1E3A8A').rect(20, 20, width - 40, height - 40).stroke();
    doc.lineWidth(0.5).strokeColor('#D97706').rect(24, 24, width - 48, height - 48).stroke();

    // Institutional Header
    doc.font('Helvetica-Bold').fontSize(20).fillColor('#1E3A8A').text(data.schoolName.toUpperCase(), margin, 35, { align: 'center', width: contentWidth });
    if (data.schoolTagline) {
      doc.font('Helvetica-Oblique').fontSize(9.5).fillColor('#6B7280').text(data.schoolTagline, margin, 58, { align: 'center', width: contentWidth });
    }

    // Badge / Subtitle
    const badgeY = 75;
    doc.rect(margin + contentWidth / 2 - 180, badgeY, 360, 24).fillAndStroke('#EFF6FF', '#93C5FD');
    doc.font('Helvetica-Bold').fontSize(11).fillColor('#1D4ED8').text(
      `CLASS TIMETABLE: ${data.className} (${data.academicYear})`,
      margin + contentWidth / 2 - 180,
      badgeY + 6,
      { align: 'center', width: 360 }
    );

    // Timetable Table Layout
    const tableTop = 115;
    const days = data.days.length > 0 ? data.days : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    const periodCount = data.periods.length > 0 ? data.periods.length : 5;

    const dayColWidth = 90;
    const periodColWidth = (contentWidth - dayColWidth) / periodCount;
    const headerHeight = 36;
    const rowHeight = Math.min(65, (height - tableTop - 60) / days.length);

    // Draw Table Header
    doc.rect(margin, tableTop, dayColWidth, headerHeight).fillAndStroke('#1E3A8A', '#1E3A8A');
    doc.font('Helvetica-Bold').fontSize(10).fillColor('#FFFFFF').text('DAY / TIME', margin, tableTop + 13, {
      width: dayColWidth,
      align: 'center',
    });

    for (let i = 0; i < periodCount; i++) {
      const p = data.periods[i] || { period: i + 1, time: `Period ${i + 1}` };
      const x = margin + dayColWidth + i * periodColWidth;
      doc.rect(x, tableTop, periodColWidth, headerHeight).fillAndStroke('#1E3A8A', '#1E3A8A');

      doc.font('Helvetica-Bold').fontSize(9.5).fillColor('#FFFFFF').text(`Period ${p.period}`, x, tableTop + 6, {
        width: periodColWidth,
        align: 'center',
      });
      if (p.time) {
        doc.font('Helvetica').fontSize(7.5).fillColor('#E0E7FF').text(p.time, x, tableTop + 20, {
          width: periodColWidth,
          align: 'center',
        });
      }
    }

    // Draw Day Rows & Cells
    for (let r = 0; r < days.length; r++) {
      const day = days[r];
      const y = tableTop + headerHeight + r * rowHeight;
      const isEvenRow = r % 2 === 0;

      // Day Column
      doc.rect(margin, y, dayColWidth, rowHeight).fillAndStroke(isEvenRow ? '#F8FAFC' : '#F1F5F9', '#CBD5E1');
      doc.font('Helvetica-Bold').fontSize(9.5).fillColor('#1E293B').text(day, margin, y + rowHeight / 2 - 5, {
        width: dayColWidth,
        align: 'center',
      });

      // Period Cells for this Day
      for (let c = 0; c < periodCount; c++) {
        const pNum = data.periods[c]?.period || c + 1;
        const cellX = margin + dayColWidth + c * periodColWidth;

        // Find entry
        const entry = data.entries.find(
          (e) => e.dayOfWeek.toLowerCase() === day.toLowerCase() && e.period === pNum
        );

        const isBreak = entry && (
          entry.subjectName.toLowerCase().includes('break') ||
          entry.subjectName.toLowerCase().includes('recess') ||
          entry.subjectName.toLowerCase().includes('lunch')
        );

        if (isBreak) {
          doc.rect(cellX, y, periodColWidth, rowHeight).fillAndStroke('#FEF3C7', '#FCD34D');
          doc.font('Helvetica-Bold').fontSize(8.5).fillColor('#B45309').text('☕ ' + entry.subjectName.toUpperCase(), cellX + 4, y + rowHeight / 2 - 9, {
            width: periodColWidth - 8,
            align: 'center',
          });
          const timeText = entry.startTime && entry.endTime ? `${entry.startTime} - ${entry.endTime}` : (data.periods[c]?.time || '');
          if (timeText) {
            doc.font('Helvetica').fontSize(7).fillColor('#D97706').text(timeText, cellX + 4, y + rowHeight / 2 + 3, {
              width: periodColWidth - 8,
              align: 'center',
            });
          }
        } else if (entry) {
          doc.rect(cellX, y, periodColWidth, rowHeight).fillAndStroke(isEvenRow ? '#FFFFFF' : '#F8FAFC', '#E2E8F0');
          doc.font('Helvetica-Bold').fontSize(9).fillColor('#1E3A8A').text(entry.subjectName, cellX + 4, y + 10, {
            width: periodColWidth - 8,
            align: 'center',
          });
          if (entry.teacherName) {
            doc.font('Helvetica').fontSize(7.5).fillColor('#475569').text(`Faculty: ${entry.teacherName}`, cellX + 4, y + 26, {
              width: periodColWidth - 8,
              align: 'center',
            });
          }
          const timeText = entry.startTime && entry.endTime ? `${entry.startTime} - ${entry.endTime}` : (data.periods[c]?.time || '');
          if (timeText) {
            doc.font('Helvetica').fontSize(6.5).fillColor('#94A3B8').text(timeText, cellX + 4, y + 40, {
              width: periodColWidth - 8,
              align: 'center',
            });
          }
        } else {
          doc.rect(cellX, y, periodColWidth, rowHeight).fillAndStroke(isEvenRow ? '#FFFFFF' : '#F8FAFC', '#E2E8F0');
          doc.font('Helvetica-Oblique').fontSize(8).fillColor('#CBD5E1').text('- Free Period -', cellX + 4, y + rowHeight / 2 - 4, {
            width: periodColWidth - 8,
            align: 'center',
          });
        }
      }
    }

    // Footer
    const footerY = height - 38;
    const nowStr = new Date().toLocaleDateString('en-US', { day: '2-digit', month: 'short', year: 'numeric' });
    doc.font('Helvetica').fontSize(7.5).fillColor('#94A3B8').text(
      `Generated on ${nowStr} • AURA EMS Enterprise School Management System • Official Schedule`,
      margin,
      footerY,
      { width: contentWidth, align: 'center' }
    );

    doc.end();
  }
}
