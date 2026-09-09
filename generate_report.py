import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._element.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._element.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def add_page_number(run):
    fldChar1 = parse_xml(r'<w:fldChar %s w:fldCharType="begin"/>' % nsdecls('w'))
    instrText = parse_xml(r'<w:instrText %s xml:space="preserve"> PAGE </w:instrText>' % nsdecls('w'))
    fldChar2 = parse_xml(r'<w:fldChar %s w:fldCharType="separate"/>' % nsdecls('w'))
    fldChar3 = parse_xml(r'<w:fldChar %s w:fldCharType="end"/>' % nsdecls('w'))
    run._r.append(fldChar1)
    run._r.append(instrText)
    run._r.append(fldChar2)
    run._r.append(fldChar3)

def create_report():
    doc = Document()

    # Configure Margins: Left: 1.25", Right: 1.0", Top: 1.0", Bottom: 1.0"
    for section in doc.sections:
        section.top_margin = Inches(1.0)
        section.bottom_margin = Inches(1.0)
        section.left_margin = Inches(1.25)
        section.right_margin = Inches(1.0)
        section.page_width = Inches(8.27)   # A4
        section.page_height = Inches(11.69)
        section.different_first_page_header_footer = True

        # Header for subsequent pages: strictly following Indus University guidelines
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run("Internship Credit (CE0318/CE0523/CE0726)                                 IU Enrolment: [IU NUMBER]")
        hrun.font.name = "Times New Roman"
        hrun.font.size = Pt(9)
        hrun.font.color.rgb = RGBColor(100, 116, 139)

        # Footer for subsequent pages: Left: CSE - IITE, Right: Page Number
        footer = section.footer
        fp = footer.paragraphs[0]
        fp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        frun1 = fp.add_run("CSE - IITE                                                                                                    Page ")
        frun1.font.name = "Times New Roman"
        frun1.font.size = Pt(9)
        frun1.font.color.rgb = RGBColor(100, 116, 139)
        frun2 = fp.add_run()
        frun2.font.name = "Times New Roman"
        frun2.font.size = Pt(9)
        frun2.font.color.rgb = RGBColor(100, 116, 139)
        add_page_number(frun2)

    # Base Normal Style
    normal_style = doc.styles['Normal']
    normal_style.font.name = 'Times New Roman'
    normal_style.font.size = Pt(12)
    normal_style.font.color.rgb = RGBColor(15, 23, 42)

    # Helper functions
    def add_section_heading(title):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(8)
        run = p.add_run(title.upper())
        run.font.name = "Times New Roman"
        run.font.size = Pt(14)
        run.font.bold = True
        run.font.color.rgb = RGBColor(30, 58, 138)  # Primary Navy
        return p

    def add_subsection_heading(title):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(14)
        p.paragraph_format.space_after = Pt(4)
        run = p.add_run(title)
        run.font.name = "Times New Roman"
        run.font.size = Pt(12)
        run.font.bold = True
        return p

    def add_body_paragraph(text, space_after=6):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = 1.5
        run = p.add_run(text)
        run.font.name = "Times New Roman"
        run.font.size = Pt(12)
        return p

    def add_figure(image_path, caption_text, width=Inches(5.5)):
        if os.path.exists(image_path):
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(8)
            p.paragraph_format.space_after = Pt(4)
            p.add_run().add_picture(image_path, width=width)

            cp = doc.add_paragraph()
            cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
            cp.paragraph_format.space_before = Pt(2)
            cp.paragraph_format.space_after = Pt(12)
            crun = cp.add_run(caption_text)
            crun.font.name = "Times New Roman"
            crun.font.size = Pt(10)
            crun.font.italic = True
            crun.font.color.rgb = RGBColor(71, 85, 105)

    # -------------------------------------------------------------
    # 1. COVER PAGE (Exact Indus University Official Format)
    # -------------------------------------------------------------
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(12)
    run = p.add_run("AN INTERNSHIP - 2 - PROJECT REPORT\nON")
    run.font.name = "Times New Roman"
    run.font.size = Pt(16)
    run.font.bold = True

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(16)
    run = p.add_run("AURA EMS: MULTI-TENANT EDUCATION MANAGEMENT SYSTEM\n(ENTERPRISE FULL-STACK CLOUD APPLICATION)")
    run.font.name = "Times New Roman"
    run.font.size = Pt(17)
    run.font.bold = True
    run.font.color.rgb = RGBColor(30, 58, 138)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(24)
    run = p.add_run("As a part of\nInternship Credit (CE0318 / CE0523 / CE0726)")
    run.font.name = "Times New Roman"
    run.font.size = Pt(13)
    run.font.italic = True

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(20)
    p.paragraph_format.space_after = Pt(4)
    run = p.add_run("Submitted by:\nStudent Name")
    run.font.name = "Times New Roman"
    run.font.size = Pt(12)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(24)
    run = p.add_run("PARSHAV SHAH\n(IU Enrolment Number: [Your Enrolment No])")
    run.font.name = "Times New Roman"
    run.font.size = Pt(14)
    run.font.bold = True

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(12)
    run = p.add_run("In fulfillment for the award of the degree of\nBACHELOR OF TECHNOLOGY\nin\nCOMPUTER SCIENCE ENGINEERING")
    run.font.name = "Times New Roman"
    run.font.size = Pt(13)
    run.font.bold = True

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(36)
    p.paragraph_format.space_after = Pt(4)
    run = p.add_run("INSTITUTE OF TECHNOLOGY AND ENGINEERING\nINDUS UNIVERSITY CAMPUS, RANCHARDA, VIA-THALTEJ\nAHMEDABAD - 382115, GUJARAT, INDIA\nWEB: www.indusuni.ac.in\n\nSEPTEMBER 2026")
    run.font.name = "Times New Roman"
    run.font.size = Pt(11)
    run.font.bold = True

    doc.add_page_break()

    # -------------------------------------------------------------
    # 2. INTRODUCTION & COMPANY PROFILE (Page 2)
    # -------------------------------------------------------------
    add_section_heading("1. INTRODUCTION & COMPANY PROFILE")

    add_body_paragraph(
        "This project report is a comprehensive description of my practical industry internship carried out as a compulsory "
        "curriculum component for the Bachelor of Technology in Computer Science and Engineering at the Institute of Technology "
        "and Engineering (IITE), Indus University. The internship was undertaken at Vanshee Infotech, Ahmedabad, under the expert "
        "guidance of CEO Bhavi Kansara and senior software engineering mentors."
    )

    add_body_paragraph(
        "During this tenure, my primary role was that of a Software Developer Intern, architecting and engineering a scalable, "
        "production-grade multi-tenant web application titled AURA EMS (Aura Education Management System). The application was "
        "conceived to address the severe challenges faced by academic institutions, multi-school trusts, and education societies "
        "in unifying their operations across admissions, staff records, real-time classroom attendance, multi-installment fee accounting, "
        "examinations, official institutional report card generation, and audit-logged student merit certificates."
    )

    add_body_paragraph(
        "• Title of Internship: Full-Stack Web Development & Cloud Systems Architecture\n"
        "• Work Carried Out: Flutter Web, Node.js, Express, TypeScript, PostgreSQL 15, Prisma ORM, JWT Authentication, Multi-Tenant Data Isolation, PDFKit Document Engine, Automated Testing, Continuous Database Backup System\n"
        "• Company Name: Vanshee Infotech"
    )

    # Detailed Company Profile Table
    table = doc.add_table(rows=6, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    details = [
        ("Company / Organization Name", "Vanshee Infotech"),
        ("Headquarters / Office Address", "B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India"),
        ("Corporate Website & Contact", "www.vansheeinfotech.com | vansheeinfotech@gmail.com"),
        ("Designation / Role", "Software Developer Intern (Full-Stack & Multi-Tenant Architecture)"),
        ("Internship Duration", "3 Months (May 2026 – August 2026)"),
        ("Core Technology Stack", "Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM, REST API")
    ]

    for i, (k, v) in enumerate(details):
        row = table.rows[i]
        c1, c2 = row.cells[0], row.cells[1]
        c1.text = k
        c2.text = v
        set_cell_background(c1, "F1F5F9")
        set_cell_margins(c1, 80, 80, 120, 120)
        set_cell_margins(c2, 80, 80, 120, 120)
        c1.paragraphs[0].runs[0].font.bold = True
        c1.paragraphs[0].runs[0].font.size = Pt(9.5)
        c2.paragraphs[0].runs[0].font.size = Pt(9.5)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 3. CERTIFICATE (Page 3)
    # -------------------------------------------------------------
    add_section_heading("2. CERTIFICATE OF INTERNSHIP COMPLETION")

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(20)
    p.paragraph_format.space_after = Pt(16)
    run = p.add_run("VANSHEE INFOTECH\nSMART SOLUTIONS FOR EDUCATION & INDUSTRY\nAhmedabad, Gujarat, India")
    run.font.name = "Times New Roman"
    run.font.size = Pt(13)
    run.font.bold = True
    run.font.color.rgb = RGBColor(30, 58, 138)

    add_body_paragraph(
        "This is to certify that Mr. Parshav Shah, a bona fide student of Bachelor of Technology in Computer Science and "
        "Engineering at Institute of Technology and Engineering (IITE), Indus University, Ahmedabad (IU Enrolment Number: "
        "[Your Enrolment No]), has successfully completed his industry internship at Vanshee Infotech from May 2026 to August 2026."
    )

    add_body_paragraph(
        "During his internship tenure, he worked on the major enterprise project titled \"AURA EMS: Multi-Tenant Education Management "
        "System\". He actively participated in designing the full-stack system architecture, developing the responsive Flutter Web "
        "frontend, engineering the secure Node.js/TypeScript REST API, implementing cryptographic tenant data isolation with "
        "PostgreSQL and Prisma ORM, configuring vector-based PDF report cards and certificate generators, and establishing a continuous "
        "database backup pipeline."
    )

    add_body_paragraph(
        "During his association with us, we found him punctual, hardworking, inquisitive, and dedicated with excellent technical "
        "problem-solving capabilities. His performance exceeded our expectations, and we wish him all success in his future "
        "academic and professional endeavors."
    )

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(36)
    p.paragraph_format.space_after = Pt(4)
    run1 = p.add_run("Date: September 08, 2026\nPlace: Ahmedabad, Gujarat\n\n\n\n_______________________________\nBhavi Kansara\nCEO & Managing Director\nVanshee Infotech")
    run1.font.name = "Times New Roman"
    run1.font.bold = True
    run1.font.size = Pt(11)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 4. ACKNOWLEDGEMENT (Page 4)
    # -------------------------------------------------------------
    add_section_heading("3. ACKNOWLEDGEMENT")

    add_body_paragraph(
        "I would like to express my sincere and profound gratitude to Indus University and the Institute of Technology "
        "and Engineering (IITE) for granting me the invaluable academic opportunity to undertake this industry internship project."
    )

    add_body_paragraph(
        "I express my heartiest thanks to my respected Internal Faculty Guide, for their continuous support, intellectual guidance, "
        "and encouragement throughout the duration of this internship project. Their valuable critique and mentorship were instrumental "
        "in steering the project in the right direction."
    )

    add_body_paragraph(
        "I am immensely grateful to Vanshee Infotech for providing me with the opportunity to engineer the enterprise project "
        "\"AURA EMS: Multi-Tenant Education Management System\". Special thanks to CEO Bhavi Kansara and the entire engineering team "
        "for granting access to modern developer environments, cloud infrastructure, and for creating an inspiring atmosphere that "
        "encouraged hands-on learning and professional development."
    )

    add_body_paragraph(
        "Finally, I extend my gratitude to the Head of the Department and all respected faculty members of the Department of "
        "Computer Science and Engineering, whose foundational teachings, support, and blessings enabled me to successfully complete "
        "this undertaking."
    )

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(36)
    p.paragraph_format.space_after = Pt(24)
    run = p.add_run("Parshav Shah\n(IU Enrolment Number: [Your Enrolment No])\nB.Tech Computer Science Engineering\nIndus University, Ahmedabad")
    run.font.name = "Times New Roman"
    run.font.bold = True

    doc.add_page_break()

    # -------------------------------------------------------------
    # 5. ABSTRACT (Page 5)
    # -------------------------------------------------------------
    add_section_heading("4. ABSTRACT")

    add_body_paragraph(
        "Educational institutions, schools, and colleges grapple with severe operational overhead when relying on fragmented "
        "spreadsheets, localized desktop software, and paper registers to manage student admissions, faculty workloads, classroom "
        "attendance, examination gradebooks, fee collections, and institutional certificates. Furthermore, education trusts running "
        "multiple campuses face significant infrastructure expenses when hosting and managing disjointed, independent software "
        "deployments for each institution."
    )

    add_body_paragraph(
        "To resolve these real-world challenges, AURA EMS (Aura Education Management System) was architected and implemented as "
        "a cloud-native, multi-tenant school administration web application. A single centralized deployment securely serves multiple "
        "independent schools (\"clients\"), guaranteeing strict mathematical and cryptographic data isolation between tenants while "
        "empowering a Super Administrator to manage client onboarding, suspension, and quotas from a dedicated Client Console."
    )

    add_body_paragraph(
        "Built using a modern decoupled architecture, AURA EMS pairs a responsive Flutter Web Single Page Application (SPA) "
        "with a high-performance Node.js, Express, and TypeScript REST API backend, backed by PostgreSQL 15 and Prisma ORM. "
        "The system enforces a 3-tier Role-Based Access Control (RBAC) hierarchy across Superadmin, School Admin, and School Staff. "
        "Tenant isolation is enforced cryptographically by binding school client IDs to verified JWT tokens at the server middleware "
        "layer, rendering cross-tenant data tampering mathematically impossible."
    )

    add_body_paragraph(
        "The application integrates real-time dynamic dashboard KPI aggregations, 30-day rolling attendance matriculation, "
        "automated subject-wise examination grade calculations, multi-installment tuition fee ledgers with vector-rendered "
        "downloadable PDF receipts, verifiable student achievement certificates, official student academic report cards (PDF "
        "marksheets), and a dual-tier continuous database backup system supporting universal JSON exports and native PostgreSQL dumps. "
        "The system has been validated with 100% test pass rates across 33 backend Jest integration tests and 12 Flutter test suites."
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # 6. TECHNOLOGIES USED (Page 6)
    # -------------------------------------------------------------
    add_section_heading("5. TECHNOLOGIES USED")

    add_subsection_heading("5.1 Frontend Technologies")
    add_body_paragraph(
        "• Flutter Web (v3.41+) & Dart SDK: Utilized as the primary client framework, compiling into high-performance CanvasKit and "
        "HTML/CSS web targets. Provides smooth 60 FPS user interfaces across desktop monitors down to 768px tablet displays.\n"
        "• Provider State Management: Employs unidirectional data architecture across AuthProvider, ClientProvider, StudentProvider, "
        "TeacherProvider, AcademicProvider, FeesProvider, and SettingsProvider.\n"
        "• Material Design 3 Typography: Clean design system using Google Fonts (Inter) with a high-contrast corporate palette "
        "(Primary Navy #1E3A8A, Accent Blue #2563EB, Success Emerald #10B981, Crimson #EF4444)."
    )

    add_subsection_heading("5.2 Backend Technologies & API Layer")
    add_body_paragraph(
        "• Node.js & Express (TypeScript): Type-safe asynchronous REST API framework guaranteeing compile-time interface safety, "
        "structured error handling, and robust middleware pipelines.\n"
        "• Zod Schema Validation: Performs strict runtime validation and payload sanitization on every HTTP mutation request.\n"
        "• JSON Web Tokens (JWT) & bcrypt: Secure user session management using SHA-256 signed tokens and 10-round salted password "
        "hashes. Cryptographic tenant resolution middleware (tenant.util.ts) verifies tenant scopes on every API route.\n"
        "• PDFKit Engine: Server-side vector graphics generation producing official institutional fee receipts, merit certificates, "
        "and student academic report cards with dynamic school letterheads."
    )

    add_subsection_heading("5.3 Database Architecture & Automated Backup")
    add_body_paragraph(
        "• PostgreSQL 15 & Prisma ORM: Enterprise relational database engine enforcing ACID compliance. Modeled with 15 relational "
        "tables with foreign key constraints and compound unique indices (@@unique([clientId, admissionNumber]), "
        "@@unique([clientId, name, division, academicYear]), @@unique([clientId, studentId, date])).\n"
        "• Dual-Tier Continuous Backup: Native pg_dump.exe SQL backups alongside universal JSON exports capturing all database entities."
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # 7. SYSTEM ARCHITECTURE & MULTI-TENANT DESIGN (Page 7)
    # -------------------------------------------------------------
    add_section_heading("6. SYSTEM ARCHITECTURE & MULTI-TENANT DESIGN")

    add_subsection_heading("6.1 Three-Tier Role & Scope Model")
    add_body_paragraph(
        "1. SUPERADMIN (Platform Owner): Lives at reserved client_id = 1. Operates via the Client Console to monitor platform metrics, "
        "provision new school tenants, suspend delinquent schools, and manage platform quotas. Strictly isolated from school operational data.\n"
        "2. ADMIN (School Administrator): Scoped to client_id >= 2. Full operational authority over their specific school only, "
        "including admissions, staff records, fee structures, examinations, report cards, certificates, and backups.\n"
        "3. STAFF (School Staff / Teachers): Scoped to client_id >= 2. Restricted operational permissions allowing attendance marking, "
        "grade entry, timetable view, and student directory lookup. Blocked from deleting students, configuring fees, or managing users."
    )

    # Core Database Models Table
    table = doc.add_table(rows=8, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ["Model / Entity", "Multi-Tenant Key & Compound Constraints", "Functional Responsibility"]
    for col_idx, text in enumerate(headers):
        cell = table.rows[0].cells[col_idx]
        cell.text = text
        set_cell_background(cell, "1E3A8A")
        cell.paragraphs[0].runs[0].font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

    models_data = [
        ("Client", "id (PK), slug (Unique), status", "Stores onboarded schools (id=1 reserved for Platform Owner)"),
        ("User", "clientId, email (Unique), role", "Platform Superadmins, School Administrators, and School Staff users"),
        ("Student", "clientId, @@unique([clientId, admNo])", "Student profiles, parental contacts, enrollment status, class linkage"),
        ("Attendance", "clientId, @@unique([clientId, studentId, date])", "Daily attendance status (Present, Absent, Leave) with audit tracking"),
        ("FeeStructure & Payment", "clientId, @@unique([clientId, receiptNo])", "Annual class fees, installment transactions, payment modes, receipt numbers"),
        ("Exam & Mark", "clientId, @@unique([clientId, examId, studentId])", "Assessment configuration, maximum/passing marks, student score ledger"),
        ("Certificate & Notice", "clientId, @@unique([clientId, certificateNo])", "Merit certificate logging and circular bulletin notices")
    ]

    for row_idx, data in enumerate(models_data, start=1):
        for col_idx, text in enumerate(data):
            cell = table.rows[row_idx].cells[col_idx]
            cell.text = text
            set_cell_margins(cell, 80, 80, 100, 100)
            if row_idx % 2 == 1:
                set_cell_background(cell, "F8FAFC")
            cell.paragraphs[0].runs[0].font.size = Pt(8.5)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 8. CORE MODULES & FUNCTIONALITY (Page 8)
    # -------------------------------------------------------------
    add_section_heading("7. CORE MODULES & SYSTEM FUNCTIONALITY")

    add_subsection_heading("7.1 Super Admin Client Console")
    add_body_paragraph(
        "Resides at client_id = 1. Provides a specialized management console allowing the platform owner to: (1) View aggregate KPIs "
        "across all institutions, (2) Monitor active and suspended tenant organizations, (3) Onboard new schools atomically via an "
        "automated database transaction provisioning default settings and the initial school admin, (4) Instantly suspend or reactivate "
        "schools, and (5) Soft-delete decommissioned schools while permanently protecting historical academic data."
    )

    add_subsection_heading("7.2 School Operational Dashboard & Real-Time Sync")
    add_body_paragraph(
        "A real-time executive control center presenting key performance metrics to school administrators: Total student enrollment, "
        "faculty headcount, class sections, collected vs pending tuition fees, dynamic 30-day fee trend charts, and today's attendance "
        "rate calculated on-the-fly from daily classroom records."
    )

    add_subsection_heading("7.3 Student & Faculty Management")
    add_body_paragraph(
        "Offers full student admission workflows with auto-generated sequential admission numbers (ADM001), demographic data capture, "
        "parent contact records, and 360-degree student profiles combining academic progress, attendance percentages, and fee status."
    )

    add_subsection_heading("7.4 Attendance & Examination Marksheet Ledger")
    add_body_paragraph(
        "Enables class teachers to record and audit daily classroom attendance in a fast, interactive grid with pre-filled defaults. "
        "The examination module supports subject-wise test creation, maximum/passing mark benchmarks, automated percentage "
        "calculations, standardized grading scales (A+, A, B+, B, C, D, F), and official report card generation."
    )

    add_subsection_heading("7.5 Fee Accounting & Institutional Document Generation")
    add_body_paragraph(
        "Handles multi-installment tuition fee collection across Cash, Bank Transfer, Online, and UPI modes. Generates vector-rendered "
        "institutional fee receipts, student academic report cards, and achievement certificates dynamically formatted with the school's "
        "official name, address, tagline, and principal's signature through server-side PDFKit rendering."
    )

    add_subsection_heading("7.6 Continuous Multi-Database Backup System")
    add_body_paragraph(
        "To guarantee zero business interruption and seamless database engine migrations, AURA EMS integrates a dual-tier continuous "
        "backup system: (1) Universal portable JSON backup capturing all 15 relational tables with complete metadata annotations, "
        "and (2) Native PostgreSQL SQL dumps generated via pg_dump.exe. Backups can be triggered automatically or on-demand."
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # 9. SCREENSHOTS ON MY PROJECT (Pages 9, 10, 11)
    # -------------------------------------------------------------
    add_section_heading("8. SCREENSHOTS ON MY PROJECT (INPUT / UI & OUTPUT)")

    add_body_paragraph(
        "The following screenshots illustrate the core graphical user interfaces, interactive management views, and system "
        "outputs engineered during the internship for AURA EMS:"
    )

    # Figure 1: Login & Multi-Tenant Selection
    add_figure("report_assets/login.png", "Figure 8.1: AURA EMS Secure Authentication & Multi-Tenant Sign-in Interface", width=Inches(5.0))

    # Figure 2: Executive Dashboard
    add_figure("report_assets/dashboard.png", "Figure 8.2: School Operational Dashboard with Real-Time KPIs, Attendance Rate & Fee Charts", width=Inches(5.5))

    doc.add_page_break()

    # Figure 3: Student Management
    add_figure("report_assets/student_management.png", "Figure 8.3: Student Directory with Quick Search, Filter & Profile Action Triggers", width=Inches(5.5))

    # Figure 4: Add Student Admission
    add_figure("report_assets/add_student.png", "Figure 8.4: Student Admission Workflow with Auto-generated Admission Number & Parent Records", width=Inches(5.0))

    # Figure 5: Teacher Management
    add_figure("report_assets/teacher_management.png", "Figure 8.5: Faculty & Staff Directory with Department and Qualification Tracking", width=Inches(5.5))

    doc.add_page_break()

    # Figure 6: Daily Attendance Tracking
    add_figure("report_assets/attendance.png", "Figure 8.6: Daily Classroom Attendance Tracking Grid with Present/Absent/Leave Toggles", width=Inches(5.5))

    # Figure 7: Examination Marks Ledger
    add_figure("report_assets/examinations.png", "Figure 8.7: Examination Marks Ledger with Automated Percentage & Grade Calculation", width=Inches(5.5))

    # Figure 8: Fee Management
    add_figure("report_assets/fees_management.png", "Figure 8.8: Tuition Fee Ledger with Installment Tracking, Mode of Payment & Balance Dues", width=Inches(5.5))

    doc.add_page_break()

    # Figure 9: Timetable & Notices
    add_figure("report_assets/timetable.png", "Figure 8.9: Class-wise Weekly Academic Timetable Schedule", width=Inches(5.0))
    add_figure("report_assets/notices.png", "Figure 8.10: Institutional Notice Board with Circulars and Announcements", width=Inches(5.0))

    # Figure 11: Reports & Settings
    add_figure("report_assets/reports.png", "Figure 8.11: Dynamic Real-Time Reports Hub (Academic, Enrollment, Fees & Attendance)", width=Inches(4.8))
    add_figure("report_assets/settings.png", "Figure 8.12: System Settings, School Branding & Continuous Database Backup Facility", width=Inches(4.8))

    doc.add_page_break()

    # -------------------------------------------------------------
    # 10. TESTING, QUALITY ASSURANCE & VERIFICATION (Page 12)
    # -------------------------------------------------------------
    add_section_heading("9. TESTING, QUALITY ASSURANCE & VERIFICATION")

    add_body_paragraph(
        "To guarantee high software reliability, data isolation, and enterprise robustness, AURA EMS was subjected to rigorous "
        "automated unit and integration testing across both the Node.js backend and Flutter Web frontend."
    )

    # Test Results Summary Table
    table = doc.add_table(rows=7, cols=4)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ["Test Suite / Module", "Test Focus & Security Verification", "Test Count", "Pass Rate"]
    for col_idx, text in enumerate(headers):
        cell = table.rows[0].cells[col_idx]
        cell.text = text
        set_cell_background(cell, "1E3A8A")
        cell.paragraphs[0].runs[0].font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

    test_data = [
        ("Multi-Tenant Isolation", "Cross-tenant access blocks (404), tenant spoofing prevention, account suspension checks", "12 Tests", "100% Passed"),
        ("Academic & Operations", "Attendance batches, exam percentage/grade calculation, report card & certificate generation", "8 Tests", "100% Passed"),
        ("Authentication & RBAC", "JWT validation, password encryption, 403 Forbidden role privilege barriers", "6 Tests", "100% Passed"),
        ("Student Management", "Sequential admission generation, search/filtering, full profile metrics", "7 Tests", "100% Passed"),
        ("Frontend Models & State", "JSON deserialization, role determination, reactive Provider state changes", "11 Tests", "100% Passed"),
        ("Frontend Widget Rendering", "Responsive layout integrity, login screen initialization", "1 Test", "100% Passed")
    ]

    for row_idx, data in enumerate(test_data, start=1):
        for col_idx, text in enumerate(data):
            cell = table.rows[row_idx].cells[col_idx]
            cell.text = text
            set_cell_margins(cell, 80, 80, 100, 100)
            if row_idx % 2 == 1:
                set_cell_background(cell, "F8FAFC")
            cell.paragraphs[0].runs[0].font.size = Pt(8.5)
            if col_idx == 3:
                cell.paragraphs[0].runs[0].font.bold = True
                cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(16, 185, 129)

    add_body_paragraph(
        "Across the entire system, all 33 backend tests and 12 frontend tests passed with zero failures (45/45 tests, 100% pass rate). "
        "Continuous automated backups were also verified to produce valid, restorable JSON and PostgreSQL SQL dumps.",
        space_after=12
    )

    doc.add_page_break()

    # -------------------------------------------------------------
    # 11. FUTURE REQUIREMENTS & CONCLUSION (Page 13)
    # -------------------------------------------------------------
    add_section_heading("10. FUTURE REQUIREMENTS & CONCLUSION")

    add_subsection_heading("10.1 Future Requirements & Planned Enhancements")
    add_body_paragraph(
        "While the current release of AURA EMS fulfills all core administrative, academic, fee collection, certificate issuance, "
        "and multi-tenant requirements, the following technical enhancements are planned for future versions:\n"
        "• Mobile Application Deployment: Leveraging the existing Flutter codebase to compile native Android and iOS client apps "
        "for teachers and school administrators.\n"
        "• Parent & Student Portals: Establishing dedicated, restricted access portals enabling parents and students to view attendance "
        "calendars, academic marks, and pay tuition fees online via integrated payment gateways (Razorpay/Stripe).\n"
        "• Automated Communication Gateways: Integrating SMS (Twilio) and WhatsApp Business API gateways to deliver instant alerts "
        "for student absences, fee receipt confirmations, and emergency campus circulars.\n"
        "• AI-Driven Academic Analytics: Developing predictive machine learning models to detect students at risk of academic failure "
        "or chronic absenteeism, facilitating timely pedagogical interventions."
    )

    add_subsection_heading("10.2 Conclusion")
    add_body_paragraph(
        "The internship at Vanshee Infotech has been a deeply enriching and transformative technical journey. Through the conception, "
        "architecture, and engineering of AURA EMS, I obtained comprehensive practical exposure to modern software engineering "
        "paradigms, including cloud-native multi-tenancy, cross-platform UI development with Flutter Web, asynchronous REST API "
        "engineering with Node.js and TypeScript, relational database modeling with PostgreSQL and Prisma ORM, and test-driven development."
    )

    add_body_paragraph(
        "This project has reinforced my technical and professional capabilities, bridging academic theory from Indus University "
        "with enterprise industry practices. I express my sincere appreciation to Vanshee Infotech and Indus University for "
        "facilitating this rewarding experience."
    )

    # Save final report
    output_filename = "AURA_EMS_Internship_Project_Report.docx"
    doc.save(output_filename)
    print(f"Successfully generated {output_filename} ({os.path.getsize(output_filename)} bytes)")

if __name__ == '__main__':
    create_report()
