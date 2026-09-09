import fs from 'fs';
import path from 'path';
import { exec } from 'child_process';
import util from 'util';
import prisma from '../config/db';

const execPromise = util.promisify(exec);

export interface BackupResult {
  filename: string;
  filepath: string;
  sizeBytes: number;
  timestamp: string;
  type: 'sql' | 'json';
}

export class BackupService {
  private static backupDir = path.resolve(process.cwd(), 'backups');

  public static ensureDirExists() {
    if (!fs.existsSync(this.backupDir)) {
      fs.mkdirSync(this.backupDir, { recursive: true });
    }
  }

  /**
   * Generates a complete JSON backup of all tables in the database.
   * This ensures 100% database engine portability (Postgres, MySQL, SQLite, etc.)
   */
  public static async createJsonBackup(): Promise<BackupResult> {
    this.ensureDirExists();
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `aura_ems_backup_${timestamp}.json`;
    const filepath = path.join(this.backupDir, filename);

    const [
      users,
      classes,
      teachers,
      subjects,
      students,
      attendance,
      exams,
      marks,
      feeStructure,
      feePayments,
      notices,
      timetable,
      certificates,
      settings,
      clients,
    ] = await Promise.all([
      prisma.user.findMany(),
      prisma.class.findMany(),
      prisma.teacher.findMany(),
      prisma.subject.findMany(),
      prisma.student.findMany(),
      prisma.attendance.findMany(),
      prisma.exam.findMany(),
      prisma.mark.findMany(),
      prisma.feeStructure.findMany(),
      prisma.feePayment.findMany(),
      prisma.notice.findMany(),
      prisma.timetable.findMany(),
      prisma.certificate.findMany(),
      prisma.setting.findMany(),
      prisma.client.findMany(),
    ]);

    const backupData = {
      version: '1.0',
      exportedAt: new Date().toISOString(),
      counts: {
        clients: clients.length,
        users: users.length,
        classes: classes.length,
        teachers: teachers.length,
        subjects: subjects.length,
        students: students.length,
        attendance: attendance.length,
        exams: exams.length,
        marks: marks.length,
        feeStructure: feeStructure.length,
        feePayments: feePayments.length,
        notices: notices.length,
        timetable: timetable.length,
        certificates: certificates.length,
        settings: settings.length,
      },
      data: {
        clients,
        users,
        classes,
        teachers,
        subjects,
        students,
        attendance,
        exams,
        marks,
        feeStructure,
        feePayments,
        notices,
        timetable,
        certificates,
        settings,
      },
    };

    fs.writeFileSync(filepath, JSON.stringify(backupData, null, 2), 'utf-8');
    const stats = fs.statSync(filepath);

    return {
      filename,
      filepath,
      sizeBytes: stats.size,
      timestamp: new Date().toISOString(),
      type: 'json',
    };
  }

  /**
   * Generates a PostgreSQL SQL dump using pg_dump if available on the system
   */
  public static async createSqlBackup(): Promise<BackupResult> {
    this.ensureDirExists();
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `aura_ems_backup_${timestamp}.sql`;
    const filepath = path.join(this.backupDir, filename);

    const pgDumpPath = 'C:\\Program Files\\PostgreSQL\\15\\bin\\pg_dump.exe';
    const hasPgDump = fs.existsSync(pgDumpPath);

    if (hasPgDump) {
      const cmd = `set PGPASSWORD=2304Parshav@&& "${pgDumpPath}" -U postgres -h 127.0.0.1 -p 5432 -d aura_ems -F p -f "${filepath}"`;
      try {
        await execPromise(cmd, { shell: 'cmd.exe' });
        const stats = fs.statSync(filepath);
        return {
          filename,
          filepath,
          sizeBytes: stats.size,
          timestamp: new Date().toISOString(),
          type: 'sql',
        };
      } catch (err) {
        console.warn('pg_dump failed, falling back to JSON backup:', err);
      }
    }

    // Fallback to JSON
    return this.createJsonBackup();
  }

  /**
   * List all stored backups
   */
  public static listBackups(): Array<{ filename: string; sizeBytes: number; createdAt: Date }> {
    this.ensureDirExists();
    const files = fs.readdirSync(this.backupDir);
    return files
      .filter(f => f.startsWith('aura_ems_backup_'))
      .map(f => {
        const fullPath = path.join(this.backupDir, f);
        const stats = fs.statSync(fullPath);
        return {
          filename: f,
          sizeBytes: stats.size,
          createdAt: stats.birthtime,
        };
      })
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
  }
}
