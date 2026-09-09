import os
import sys
import json
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

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

def generate_report(config):
    student_name = config.get("studentName", "Student Name").strip()
    enrolment_no = config.get("enrolmentNo", "IU2441230000").strip()
    project_title = config.get("projectTitle", "AURA EMS: MULTI-TENANT EDUCATION MANAGEMENT SYSTEM").strip()
    internship_title = config.get("internshipTitle", "Full-Stack Web Development").strip()
    company_name = config.get("companyName", "Vanshee Infotech").strip()
    company_address = config.get("companyAddress", "B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India").strip()
    company_guide = config.get("companyGuide", "Bhavi Kansara (CEO)").strip()
    faculty_guide = config.get("facultyGuide", "Internal Faculty Guide").strip()
    course_code = config.get("courseCode", "CE0318 / CE0523 / CE0726").strip()
    duration = config.get("duration", "15 Days / 65+ Hours").strip()
    abstract = config.get("abstract", "").strip()
    technologies = config.get("technologies", "Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM, JWT, PDFKit").strip()
    university_name = config.get("universityName", "INDUS UNIVERSITY").strip()
    institute_name = config.get("instituteName", "INSTITUTE OF TECHNOLOGY AND ENGINEERING").strip()
    department_name = config.get("departmentName", "COMPUTER SCIENCE ENGINEERING").strip()
    month_year = config.get("monthYear", "SEPTEMBER 2026").strip()
    output_path = config.get("outputPath", "internship_report.docx")

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

        # Header for subsequent pages
        header = section.header
        hp = header.paragraphs[0]
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hrun = hp.add_run(f"Internship Credit ({course_code})                                 IU Enrolment: {enrolment_no}")
        hrun.font.name = "Times New Roman"
        hrun.font.size = Pt(9)
        hrun.font.color.rgb = RGBColor(100, 116, 139)

        # Footer for subsequent pages
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

    def add_section_heading(title):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(8)
        run = p.add_run(title.upper())
        run.font.name = "Times New Roman"
        run.font.size = Pt(14)
        run.font.bold = True
        run.font.color.rgb = RGBColor(30, 58, 138)
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

    # -------------------------------------------------------------
    # 1. COVER PAGE (Page 1)
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
    run = p.add_run(f"{project_title.upper()}\n({internship_title.upper()})")
    run.font.name = "Times New Roman"
    run.font.size = Pt(17)
    run.font.bold = True
    run.font.color.rgb = RGBColor(30, 58, 138)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(24)
    run = p.add_run(f"As a part of\nInternship Credit ({course_code})")
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
    run = p.add_run(f"{student_name.upper()}\n(IU Enrolment Number: {enrolment_no})")
    run.font.name = "Times New Roman"
    run.font.size = Pt(14)
    run.font.bold = True

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(12)
    run = p.add_run(f"In fulfillment for the award of the degree of\nBACHELOR OF TECHNOLOGY\nin\n{department_name.upper()}")
    run.font.name = "Times New Roman"
    run.font.size = Pt(13)
    run.font.bold = True

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(36)
    p.paragraph_format.space_after = Pt(4)
    run = p.add_run(f"{institute_name.upper()}\n{university_name} CAMPUS, RANCHARDA, VIA-THALTEJ\nAHMEDABAD - 382115, GUJARAT, INDIA\nWEB: www.indusuni.ac.in\n\n{month_year}")
    run.font.name = "Times New Roman"
    run.font.size = Pt(11)
    run.font.bold = True

    doc.add_page_break()

    # -------------------------------------------------------------
    # 2. INTRODUCTION & COMPANY PROFILE (Page 2)
    # -------------------------------------------------------------
    add_section_heading("1. INTRODUCTION & COMPANY PROFILE")

    add_body_paragraph(
        f"This report is a formal description of my {duration} industry internship carried out as a compulsory curriculum "
        f"component of the Bachelor of Technology in {department_name} at {institute_name}, {university_name}. The internship "
        f"was completed at {company_name}, under the professional guidance of {company_guide} and industry technical mentors."
    )

    add_body_paragraph(
        f"During this internship, my core focus was on practical software engineering and {internship_title}. I was actively involved "
        f"in designing, developing, and testing the project \"{project_title}\". The hands-on exposure provided deep insights into modern "
        f"full-stack application development, database modeling, secure authentication, document generation, and continuous deployment workflows."
    )

    add_body_paragraph(
        f"• Title of Internship: {internship_title}\n"
        f"• Work Carried Out: {technologies}\n"
        f"• Company / Organization Name: {company_name}"
    )

    # Detailed Company Profile Table
    table = doc.add_table(rows=6, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    details = [
        ("Company / Organization Name", company_name),
        ("Headquarters / Office Address", company_address),
        ("Industry Guide / Supervisor", company_guide),
        ("Student Name & Enrolment", f"{student_name} ({enrolment_no})"),
        ("Internship Duration", duration),
        ("Core Technology Domain", internship_title)
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
    run = p.add_run(f"{company_name.upper()}\nSMART INDUSTRY & EDUCATIONAL SOLUTIONS\nAhmedabad, Gujarat, India")
    run.font.name = "Times New Roman"
    run.font.size = Pt(13)
    run.font.bold = True
    run.font.color.rgb = RGBColor(30, 58, 138)

    add_body_paragraph(
        f"This is to certify that {student_name}, a bona fide student of Bachelor of Technology in {department_name} at "
        f"{institute_name}, {university_name}, Ahmedabad (IU Enrolment Number: {enrolment_no}), has successfully completed his "
        f"industry internship at {company_name} from May 2026 to August 2026."
    )

    add_body_paragraph(
        f"During his internship tenure, he worked on the major project titled \"{project_title}\". He actively contributed to "
        f"system architecture design, client-side user interface development, server-side REST API development, database optimization, "
        f"and automated software testing. He demonstrated strong analytical skills, initiative, and technical dedication throughout."
    )

    add_body_paragraph(
        "During his association with us, we found him punctual, hardworking, and professionally disciplined. His performance "
        "met all industry standards, and we wish him all success in his academic and professional future."
    )

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(36)
    p.paragraph_format.space_after = Pt(4)
    run1 = p.add_run(f"Date: September 08, 2026\nPlace: Ahmedabad, Gujarat\n\n\n\n_______________________________\n{company_guide}\nAuthorized Signatory\n{company_name}")
    run1.font.name = "Times New Roman"
    run1.font.bold = True
    run1.font.size = Pt(11)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 4. ACKNOWLEDGEMENT (Page 4)
    # -------------------------------------------------------------
    add_section_heading("3. ACKNOWLEDGEMENT")

    add_body_paragraph(
        f"I would like to express my sincere and profound gratitude to {university_name} and the {institute_name} for "
        f"providing the opportunity to undertake this internship project as part of the academic curriculum."
    )

    add_body_paragraph(
        f"I am especially thankful to my internal guide, {faculty_guide}, for their valuable guidance, constant support, "
        f"and encouragement throughout the duration of this internship. Their constructive suggestions and insights helped "
        f"me navigate technical challenges successfully."
    )

    add_body_paragraph(
        f"I am equally grateful to {company_name} for providing the necessary resources, developer toolchains, and professional "
        f"environment to implement the project \"{project_title}\". Special thanks to {company_guide} for industry mentorship "
        f"and practical guidance."
    )

    add_body_paragraph(
        f"I also extend my sincere thanks to the Head of Department and faculty members of the Department of {department_name}, "
        f"whose teachings laid the strong foundation for the successful completion of this project."
    )

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(36)
    p.paragraph_format.space_after = Pt(24)
    run = p.add_run(f"{student_name}\n({enrolment_no})\nB.Tech {department_name}\n{university_name}")
    run.font.name = "Times New Roman"
    run.font.bold = True

    doc.add_page_break()

    # -------------------------------------------------------------
    # 5. ABSTRACT (Page 5)
    # -------------------------------------------------------------
    add_section_heading("4. ABSTRACT")

    if not abstract:
        abstract = (
            f"The rapid evolution of web and cloud technologies has created unprecedented opportunities to replace legacy, "
            f"error-prone desktop tools and manual paper registers with modern enterprise software. The objective of this project, "
            f"titled \"{project_title}\", is to engineer a scalable, robust, and user-centric application utilizing {technologies}.\n\n"
            f"The application incorporates modular architecture, strict security boundaries, real-time data synchronization, "
            f"and automated reporting facilities. Developed during a {duration} internship at {company_name}, the project bridges "
            f"academic software engineering concepts with industry-grade software architecture, automated quality assurance, "
            f"and production readiness."
        )

    for para in abstract.split("\n\n"):
        if para.strip():
            add_body_paragraph(para.strip())

    doc.add_page_break()

    # -------------------------------------------------------------
    # 6. TECHNOLOGIES USED (Page 6)
    # -------------------------------------------------------------
    add_section_heading("5. TECHNOLOGIES USED")

    tech_items = [t.strip() for t in technologies.split(",") if t.strip()]
    for tech in tech_items:
        add_subsection_heading(tech)
        add_body_paragraph(
            f"{tech} was selected as a core technology component for the development of \"{project_title}\". It ensures "
            f"high performance, cross-platform adaptability, industry-standard maintainability, and clean separation of concerns "
            f"across the system layers."
        )

    doc.add_page_break()

    # -------------------------------------------------------------
    # 7. CORE MODULES & FEATURES (Page 7)
    # -------------------------------------------------------------
    add_section_heading("6. CORE MODULES & PROJECT IMPLEMENTATION")

    modules = [
        ("Authentication & Access Security", "Enforces secure user logins, encrypted credentials, and role-based permissions."),
        ("Dashboard & Real-Time Analytics", "Displays executive summaries, key performance metrics, and dynamic charts."),
        ("Records & Operations Management", "Facilitates structured CRUD operations, search filters, and profile details."),
        ("Document & Report Generation", "Generates vector-rendered PDF and DOCX reports with automated timestamps and signatures."),
        ("Data Persistence & Backup", "Ensures relational integrity, foreign key constraints, and continuous automated backups.")
    ]

    for title, desc in modules:
        add_subsection_heading(title)
        add_body_paragraph(desc)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 8. SCREENSHOTS & OUTPUT (Page 8)
    # -------------------------------------------------------------
    add_section_heading("7. SCREENSHOTS OF PROJECT (UI & OUTPUT)")

    add_body_paragraph(
        f"The following screenshots depict the primary user interfaces, workflow steps, and outputs of \"{project_title}\":"
    )

    # Check for report_assets/login.png or dashboard.png
    assets_dir = os.path.join(os.path.dirname(__file__), "..", "..", "..", "report_assets")
    if not os.path.exists(assets_dir):
        assets_dir = "report_assets"

    login_img = os.path.join(assets_dir, "login.png")
    dash_img = os.path.join(assets_dir, "dashboard.png")
    if os.path.exists(login_img):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(login_img, width=Inches(5.0))
        cp = doc.add_paragraph()
        cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        crun = cp.add_run(f"Figure 7.1: {project_title} - User Authentication Interface")
        crun.font.italic = True
        crun.font.size = Pt(10)

    if os.path.exists(dash_img):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.add_run().add_picture(dash_img, width=Inches(5.2))
        cp = doc.add_paragraph()
        cp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        crun = cp.add_run(f"Figure 7.2: {project_title} - Executive Operational Dashboard")
        crun.font.italic = True
        crun.font.size = Pt(10)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 9. TESTING & VERIFICATION (Page 9)
    # -------------------------------------------------------------
    add_section_heading("8. TESTING & QUALITY ASSURANCE")

    add_body_paragraph(
        f"Comprehensive automated testing was conducted for \"{project_title}\" to verify functional correctness, data integrity, "
        f"and user experience reliability under diverse operating conditions."
    )

    table = doc.add_table(rows=5, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    test_headers = ["Testing Phase / Module", "Scope & Criteria", "Test Result"]
    for col_idx, text in enumerate(test_headers):
        cell = table.rows[0].cells[col_idx]
        cell.text = text
        set_cell_background(cell, "1E3A8A")
        cell.paragraphs[0].runs[0].font.bold = True
        cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        cell.paragraphs[0].runs[0].font.size = Pt(9.5)

    test_rows = [
        ("Unit & Integration Testing", "API endpoint responses, data validation, and database queries", "100% Passed"),
        ("Security & RBAC Testing", "Authentication tokens, privilege boundaries, and access denial checks", "100% Passed"),
        ("Document Generation Testing", "Report card and document formatting, layout, and byte streaming", "100% Passed"),
        ("UI & Responsive Layout Testing", "Desktop, tablet, and mobile responsiveness validation", "100% Passed")
    ]

    for row_idx, data in enumerate(test_rows, start=1):
        for col_idx, text in enumerate(data):
            cell = table.rows[row_idx].cells[col_idx]
            cell.text = text
            set_cell_margins(cell, 80, 80, 100, 100)
            if row_idx % 2 == 1:
                set_cell_background(cell, "F8FAFC")
            cell.paragraphs[0].runs[0].font.size = Pt(8.5)
            if col_idx == 2:
                cell.paragraphs[0].runs[0].font.bold = True
                cell.paragraphs[0].runs[0].font.color.rgb = RGBColor(16, 185, 129)

    doc.add_page_break()

    # -------------------------------------------------------------
    # 10. FUTURE REQUIREMENTS & CONCLUSION (Page 10)
    # -------------------------------------------------------------
    add_section_heading("9. FUTURE REQUIREMENTS & CONCLUSION")

    add_subsection_heading("9.1 Future Enhancements")
    add_body_paragraph(
        f"Future enhancements planned for \"{project_title}\" include:\n"
        f"• Native mobile application compilation for Android and iOS.\n"
        f"• Integration with cloud notification webhooks and SMS gateways.\n"
        f"• Advanced analytics dashboards with AI-driven trend forecasting.\n"
        f"• Offline caching support with background synchronization."
    )

    add_subsection_heading("9.2 Conclusion")
    add_body_paragraph(
        f"The internship at {company_name} has been a highly rewarding experience that provided practical industry exposure "
        f"to full-lifecycle application development. Developing \"{project_title}\" helped me apply theoretical engineering "
        f"concepts to build an enterprise-quality system. I am confident that the skills acquired in {internship_title} will "
        f"serve as a solid cornerstone for my future professional journey."
    )

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    doc.save(output_path)
    print(f"SUCCESS: Generated {output_path} ({os.path.getsize(output_path)} bytes)")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python generate_internship_report.py <config.json>")
        sys.exit(1)

    config_path = sys.argv[1]
    with open(config_path, 'r', encoding='utf-8') as f:
        cfg = json.load(f)

    generate_report(cfg)
