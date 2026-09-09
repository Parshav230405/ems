# AN INTERNSHIP PROJECT REPORT
### ON
# **AURA EMS: MULTI-TENANT EDUCATION MANAGEMENT SYSTEM**
*(FULL-STACK CLOUD APPLICATION)*

---

**As a part of Internship Credit (CE0318 / CE0523 / CE0726)**

**Submitted by:**  
**PARSHAV SHAH**  
*(IU Enrolment Number: [Insert Enrolment Number])*

**In fulfillment for the award of the degree of**  
### **BACHELOR OF TECHNOLOGY**
**in**  
### **COMPUTER SCIENCE ENGINEERING**

<br>

**INSTITUTE OF TECHNOLOGY AND ENGINEERING**  
**INDUS UNIVERSITY CAMPUS, RANCHARDA, VIA-THALTEJ**  
**AHMEDABAD - 382115, GUJARAT, INDIA**  
**WEB: [www.indusuni.ac.in](https://www.indusuni.ac.in)**  

**SEPTEMBER 2026**

---

## 1. INTRODUCTION & COMPANY PROFILE

This project report is a comprehensive documentation of my industry internship carried out as an essential curriculum requirement for the Bachelor of Technology in Computer Science and Engineering at the Institute of Technology and Engineering (IITE), Indus University, Ahmedabad. The internship was completed at **Vanshee Infotech**, Ahmedabad, under the guidance of Chief Executive Officer Bhavi Kansara and senior software engineering mentors.

During this internship, I served as a **Software Developer Intern**, focusing on architecting and developing a production-grade multi-tenant educational management web application titled **AURA EMS (Aura Education Management System)**. The application serves multiple independent schools and colleges on a single shared cloud deployment while ensuring strict data isolation, complete academic record management, automated fee accounting, institutional certificate issuance, dual continuous database backup facilities, and a dedicated **Platform Super Admin Client Console**.

### Company & Internship Summary
| Parameter | Details |
|---|---|
| **Company / Organization** | **Vanshee Infotech** |
| **Corporate Address** | B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India |
| **Website & Email** | [www.vansheeinfotech.com](https://www.vansheeinfotech.com) • vansheeinfotech@gmail.com |
| **Designation / Role** | Software Developer Intern (Full-Stack & Multi-Tenant Architecture) |
| **Internship Duration** | 3 Months (May 2026 – August 2026) |
| **Technology Domain** | Cloud Web Development (Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM) |

---

## 2. ACKNOWLEDGEMENT

I express my sincere gratitude to **Indus University, Ahmedabad**, and the **Institute of Technology and Engineering (IITE)** for providing the academic infrastructure and opportunity to undergo this practical industry internship.

I am deeply thankful to my **Faculty Guide** and the **Head of Department, Computer Science & Engineering**, for their constant support, encouragement, and technical guidance throughout the project.

I also extend my heartfelt appreciation to **Vanshee Infotech**, particularly to **CEO Bhavi Kansara** and the development team, for offering a technically enriching environment, real-time enterprise problem statements, and mentorship in modern web frameworks and multi-tenant database modeling.

**Parshav Shah**  
*Department of Computer Science and Engineering*  
*Indus University, Ahmedabad*

---

## 3. ABSTRACT

Traditional school administration workflows rely on disparate spreadsheets or isolated on-premise installations that are error-prone, lack real-time synchronization, and incur high hosting overhead for education trusts managing multiple institutions.

To address these challenges, **AURA EMS** was designed and implemented as a cloud-native, multi-tenant Education Management System. Built upon a modern decoupled architectural model, the system combines a responsive **Flutter Web** single-page application with a high-throughput **Node.js, Express, and TypeScript REST API** backed by **PostgreSQL 15** and **Prisma ORM**.

The system features a three-tier hierarchical role structure:
1. **Platform Super Admin (`SUPERADMIN`, `client_id = 1`)**: Operates an isolated Client Console for provisioning, monitoring, suspending, and soft-deleting client schools, with strict programmatic restrictions preventing access to school student data.
2. **School Administrator (`ADMIN`, `client_id >= 2`)**: Manages their specific school's student lifecycle, faculty records, fee structures, academic timetable, and circular notices.
3. **School Staff (`STAFF`, `client_id >= 2`)**: Enters daily attendance and marks, with role restrictions blocking student deletion, fee configuration, and user creation.

Data security and isolation are enforced by deriving tenant context directly from cryptographically signed **JSON Web Tokens (JWT)**, neutralizing any client-side tenant parameter manipulation. Automated integration tests verify that cross-tenant queries return a `404 Not Found`.

The platform provides real-time dashboard analytics, interactive classroom attendance matriculation, automated examination grade calculation, multi-installment fee bookkeeping with PDF receipt generation, verifiable achievement certificates, and a dual-tier continuous database backup system supporting universal JSON archives and native PostgreSQL SQL dumps. Both backend (32 tests) and frontend (12 tests) achieve a **100% automated test pass rate**.

---

## 4. TECHNOLOGIES USED & SYSTEM ARCHITECTURE

```
+-----------------------------------------------------------------------------------+
|                            AURA EMS SYSTEM ARCHITECTURE                           |
+-----------------------------------------------------------------------------------+

     [ Flutter Web Client (Chrome / Edge / Safari / Tablet) ]
                             |
                             | HTTPS / REST API (Bearer JWT Auth)
                             v
     [ Express & TypeScript Application Server (Port 5000) ]
        +-- Authentication & RBAC Middleware (JWT Verification & bcrypt)
        +-- Strict Tenant Scoping Engine (tenant.util.ts)
        +-- Zod Schema Validation Layer
        +-- PDFKit Vector Document Generation Engine
        +-- Continuous Automated DB Backup Engine (JSON + pg_dump SQL)
                             |
                             | Type-Safe Queries
                             v
     [ Prisma ORM 5 Data Access Layer ]
                             |
                             | PostgreSQL Connection Pool (Port 5432)
                             v
     [ PostgreSQL 15 Relational Database (aura_ems) ]
        +-- clients (Platform Admin at id=1, Schools at id>=2)
        +-- users, students, teachers, classes, subjects
        +-- attendance, exams, marks, fee_structure, fee_payments
        +-- timetable, notices, certificates, settings
```

### 4.1 Frontend Stack
- **Flutter Web (v3.41+) & Dart SDK (v3.11+)**: Responsive Single Page Application (SPA) designed to adapt smoothly from desktop widescreen down to 768px tablet displays.
- **Provider State Management**: Manages state reactively across 9 core providers (`AuthProvider`, `ClientProvider`, `DashboardProvider`, `StudentProvider`, `TeacherProvider`, `AcademicProvider`, `FeesProvider`, `ExamProvider`, `SettingsProvider`).
- **Design System**: Material Design 3, custom typography via Google Fonts (Inter), and an institutional corporate theme palette.

### 4.2 Backend Stack
- **Node.js, Express & TypeScript**: Strongly-typed RESTful API architecture ensuring compile-time safety and structured controller/service separation.
- **Security & Authorization**: Cryptographic JSON Web Tokens (JWT) with embedded `clientId`, bcrypt password hashing (10 salt rounds), and centralized tenant isolation helpers.
- **Zod Validation**: Runtime schema validation for all inbound request bodies.
- **PDFKit**: Server-side vector PDF generation for official fee receipts and merit certificates.

### 4.3 Database Architecture (PostgreSQL & Prisma ORM)
The database schema consists of **15 relational models** with multi-tenant foreign keys (`clientId -> Client.id`) and compound unique constraints:
- `Client`: Stores onboarded school tenants (`id = 1` reserved for Platform Admin).
- `User`: Accounts with role-based access (`SUPERADMIN`, `ADMIN`, `STAFF`).
- `Student`: `@@unique([clientId, admissionNumber])`
- `Class`: `@@unique([clientId, name, division, academicYear])`
- `Attendance`: `@@unique([clientId, studentId, date])`
- `Exam` & `Mark`: `@@unique([clientId, examId, studentId])`
- `FeeStructure` & `FeePayment`: `@@unique([clientId, receiptNo])`
- `Timetable`: `@@unique([clientId, classId, dayOfWeek, period])`
- `Certificate`: `@@unique([clientId, certificateNo])`
- `Setting`: `@@unique([clientId, key])`

---

## 5. CORE MODULES & FUNCTIONALITY

### 5.1 Super Admin Client Console (Platform Owner)
- Located at reserved `client_id = 1` ("Platform Admin").
- Monitors aggregate metrics: Total Onboarded Schools, Active Accounts, Suspended Accounts, and Total Enrolled Students.
- **Atomic School Onboarding**: Uses a Prisma interactive transaction to create the school record, provision its administrator account, and generate default institutional settings atomically.
- **Tenant Management**: Instantly toggles school status between `Active` and `Suspended`. Suspended accounts are immediately blocked from logging in with a descriptive 403 response.
- **Soft Deletion**: Safely marks schools as `deleted` while preserving historical records for compliance.

### 5.2 School Operational Dashboard
- Real-time KPIs: Student enrollment, faculty count, division count, total fee collections, pending dues, and today's attendance percentage.
- Quick widgets showing recent student admissions, active school notices, and monthly fee collection charts.

### 5.3 Student & Staff Management
- Sequential auto-generated admission numbers (e.g. `ADM001`, `ADM002`).
- 360-degree student profile aggregating academic marks, attendance percentage, and payment history.
- Full teacher directory linking assigned subjects and divisions.
- Role guard: Staff accounts are prevented from deleting student records (`403 Forbidden`).

### 5.4 Classroom Attendance Matrix
- Daily attendance grid with interactive `Present`, `Absent`, and `Leave` states.
- Batch upsert transaction ensuring fast attendance recording.

### 5.5 Examination & Grading Ledger
- Configurable maximum and passing mark thresholds per subject.
- Automated score calculation with standardized letter grades (`A+`, `A`, `B+`, `B`, `C`, `D`, `F`).

### 5.6 Fee Accounting & Institutional Document Generation
- Tracks fee installments across Cash, Bank Transfer, Online, and UPI modes.
- Generates official, printable fee receipts with institution header, student details, paid amount, and outstanding dues.
- Issues verifiable merit certificates formatted with school letterhead and principal digital signature.

### 5.7 Continuous Database Backup System
- **Universal JSON Export**: Exports all 15 tables with relational metadata for cross-engine database migrations.
- **PostgreSQL SQL Dump**: Native database dump using `pg_dump.exe`.
- Triggerable on demand via `POST /api/settings/backup` or CLI via `npm run db:backup`.

---

## 6. TESTING, QUALITY ASSURANCE & VERIFICATION

A comprehensive test suite was executed to verify security, tenant isolation, and operational reliability:

### Automated Test Results
| Test Suite | Subsystem Verified | Tests | Status |
|---|---|---|---|
| `tests/multi_tenant_isolation.test.ts` | Cross-tenant 404 access denial, tenant spoofing prevention, account suspension blocks, atomic onboarding, row 1 protection | 12 | **PASSED (100%)** |
| `tests/students.test.ts` | Tenant-scoped student CRUD, auto-numbering, 360 profile stats, staff deletion restrictions | 7 | **PASSED (100%)** |
| `tests/academic_fees.test.ts` | Dashboard aggregation, attendance batch upserts, exam grading, fee structures & backup execution | 7 | **PASSED (100%)** |
| `tests/auth.test.ts` | JWT cryptographic validation, bcrypt credential checks, role authorization guards | 6 | **PASSED (100%)** |
| `frontend/test/client_test.dart` | ClientModel JSON parsing, status computation, Superadmin vs School Admin role flags | 4 | **PASSED (100%)** |
| `frontend/test/models_test.dart` | UserModel, StudentModel, ClassModel, and DashboardSummary deserialization | 5 | **PASSED (100%)** |
| `frontend/test/auth_provider_test.dart` | Authentication state lifecycle, login/logout state transitions | 2 | **PASSED (100%)** |
| `frontend/test/widget_test.dart` | Flutter UI component rendering and theme initialization | 1 | **PASSED (100%)** |
| **TOTAL** | **Full-Stack Automated Verification** | **44** | **100% PASSED** |

---

## 7. SCREENSHOTS & DEMONSTRATION WORKFLOW

### Screen 1: Unified Authentication Screen
- Branded split-screen layout with email/password input.
- Quick-credential buttons for Super Admin (`superadmin@auraems.com`), School Admin (`admin@auraems.com`), and Staff (`staff@auraems.com`).

### Screen 2: Super Admin Client Console
- Executive dashboard displaying Total Schools, Active Accounts, Suspended Accounts, and Total Students.
- Client schools data table with status badges (`Active` / `Suspended`) and action controls.

### Screen 3: Onboard New School Modal
- Form capturing School Name, custom URL Slug, Administrator Name, Email, and Temporary Password.

### Screen 4: School Operational Dashboard
- High-level metric cards: Total Students (30), Teachers (5), Classes (3), Fees Collected (INR 1,80,000), Pending Dues, and Attendance rate (94%).

### Screen 5: Student Directory & 360 Profile
- Searchable student roster with class and admission filters.
- Detailed modal showcasing student attendance rate, fee ledger, and term exam marks.

### Screen 6: Class Attendance Management Matrix
- Daily attendance grid with default "Present" state and one-click "Save Attendance" batch upsert.

### Screen 7: Fee Accounting & Installment Payment
- Tuition fee breakdown with installment records and payment mode tracking (Cash, UPI, Bank Transfer).

### Screen 8: Generated Institutional PDF Fee Receipt
- Official vector PDF fee receipt displaying school name, receipt number, student details, paid amount, and remaining balance.

### Screen 9: Achievement Certificate Output
- Official achievement certificate generated with school letterhead, honor text, and principal digital signoff.

### Screen 10: Continuous Database Backup Verification
- Settings panel showing instant dual backup generation: portable JSON archive and PostgreSQL SQL dump.

---

## 8. CONCLUSION & FUTURE ENHANCEMENTS

The internship project **AURA EMS** was successfully architected, implemented, tested, and deployed at **Vanshee Infotech**. The application solves the operational challenges of school administration by providing a modern multi-tenant platform with robust data isolation and automated workflows.

### Future Roadmap
1. **Parent & Student Mobile Applications**: Cross-platform Flutter mobile apps for real-time homework updates, fee payment, and digital attendance alerts.
2. **Automated Payment Gateway Integration**: Razorpay and Stripe API integration for instant online fee collection and automated receipt delivery.
3. **Biometric & Facial Recognition Attendance**: AI-powered camera attendance at school entrance gates.
4. **Predictive Academic Analytics**: Machine learning models to track performance trends and identify students requiring academic assistance.

---
**Report Document Generated for Indus University (IITE), Ahmedabad**  
*Academic Year: 2026-2027*
