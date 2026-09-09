import { Request, Response } from 'express';
import prisma from '../config/db';
import { getTenantId, sanitizeTenantInput } from '../utils/tenant.util';

export class NoticesController {
  public static async listNotices(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const classId = req.query.classId as string;

      const where: any = { clientId };
      if (classId) {
        where.OR = [{ classId }, { classId: null }];
      }

      const notices = await prisma.notice.findMany({
        where,
        orderBy: { postedDate: 'desc' },
        include: {
          class: { select: { id: true, name: true, division: true } },
          user: { select: { id: true, name: true } },
        },
      });

      res.status(200).json({ data: notices });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async createNotice(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const cleanBody = sanitizeTenantInput(req.body);
      const { title, body, classId } = cleanBody;
      const postedBy = req.user?.id;

      if (!postedBy) {
        res.status(401).json({ error: 'User authentication required' });
        return;
      }

      const notice = await prisma.notice.create({
        data: {
          clientId,
          title,
          body,
          classId: classId || null,
          postedBy,
        },
        include: {
          class: true,
          user: { select: { id: true, name: true } },
        },
      });

      res.status(201).json({ message: 'Notice posted successfully', notice });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async updateNotice(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;
      const cleanBody = sanitizeTenantInput(req.body);

      const existing = await prisma.notice.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Notice not found' });
        return;
      }

      const updated = await prisma.notice.update({
        where: { id },
        data: cleanBody,
      });
      res.status(200).json({ message: 'Notice updated', notice: updated });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }

  public static async deleteNotice(req: Request, res: Response): Promise<void> {
    try {
      const clientId = getTenantId(req);
      const { id } = req.params;

      const existing = await prisma.notice.findFirst({
        where: { id, clientId },
      });
      if (!existing) {
        res.status(404).json({ error: 'Notice not found' });
        return;
      }

      await prisma.notice.delete({ where: { id } });
      res.status(200).json({ message: 'Notice deleted successfully' });
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  }
}
