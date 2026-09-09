import { Request, Response } from 'express';
import path from 'path';
import fs from 'fs';
import prisma from '../config/db';
import { BackupService } from '../services/backup.service';
import { getTenantId } from '../utils/tenant.util';

export class SettingsController {
  public static async getSettings(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const settings = await prisma.setting.findMany({
        where: { clientId },
      });
      const settingsMap: Record<string, string> = {};
      settings.forEach((s) => {
        settingsMap[s.key] = s.value;
      });

      res.status(200).json({ settings: settingsMap });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async updateSettings(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const updates = req.body;

      for (const [key, value] of Object.entries(updates)) {
        if (value !== undefined && value !== null && key !== 'clientId' && key !== 'client_id') {
          await prisma.setting.upsert({
            where: {
              clientId_key: { clientId, key },
            },
            update: { value: String(value) },
            create: { clientId, key, value: String(value) },
          });
        }
      }

      res.status(200).json({ message: 'Settings updated successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async triggerBackup(req: Request, res: Response): Promise<void> {
    try {
      const jsonBackup = await BackupService.createJsonBackup();
      const sqlBackup = await BackupService.createSqlBackup();

      res.status(200).json({
        message: 'Database backup completed successfully',
        backups: [
          {
            filename: jsonBackup.filename,
            sizeBytes: jsonBackup.sizeBytes,
            type: 'JSON (Universal Portable)',
            downloadUrl: `/api/settings/backups/${jsonBackup.filename}`,
          },
          {
            filename: sqlBackup.filename,
            sizeBytes: sqlBackup.sizeBytes,
            type: 'PostgreSQL SQL Dump',
            downloadUrl: `/api/settings/backups/${sqlBackup.filename}`,
          },
        ],
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async listBackups(req: Request, res: Response): Promise<void> {
    try {
      const backups = BackupService.listBackups();
      res.status(200).json({
        data: backups.map((b) => ({
          filename: b.filename,
          sizeBytes: b.sizeBytes,
          sizeKb: Number((b.sizeBytes / 1024).toFixed(2)),
          createdAt: b.createdAt,
          downloadUrl: `/api/settings/backups/${b.filename}`,
        })),
      });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async downloadBackupFile(req: Request, res: Response): Promise<void> {
    try {
      const { filename } = req.params;
      const safeFilename = path.basename(filename);
      const backupDir = path.resolve(process.cwd(), 'backups');
      const filePath = path.join(backupDir, safeFilename);

      if (!fs.existsSync(filePath)) {
        res.status(404).json({ error: 'Backup file not found' });
        return;
      }

      res.download(filePath, safeFilename);
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
