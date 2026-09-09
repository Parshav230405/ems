import { BackupService } from '../services/backup.service';
import prisma from '../config/db';

async function run() {
  console.log('--- Starting AURA EMS Database Backup ---');
  try {
    const jsonBackup = await BackupService.createJsonBackup();
    console.log(`JSON Backup created: ${jsonBackup.filename} (${(jsonBackup.sizeBytes / 1024).toFixed(2)} KB)`);

    const sqlBackup = await BackupService.createSqlBackup();
    console.log(`SQL Backup created: ${sqlBackup.filename} (${(sqlBackup.sizeBytes / 1024).toFixed(2)} KB)`);

    console.log('--- Backup Completed Successfully ---');
  } catch (error) {
    console.error('Backup failed:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

run();
