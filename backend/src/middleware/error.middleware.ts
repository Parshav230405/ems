import { Request, Response, NextFunction } from 'express';
import { Prisma } from '@prisma/client';

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction): void => {
  console.error('Unhandled Error:', err);

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      const target = (err.meta?.target as string[])?.join(', ') || 'field';
      res.status(409).json({
        error: `A record with this ${target} already exists.`,
        code: err.code,
      });
      return;
    }
    if (err.code === 'P2003') {
      res.status(400).json({
        error: 'Foreign key constraint failed. Related record does not exist or cannot be deleted.',
        code: err.code,
      });
      return;
    }
    if (err.code === 'P2025') {
      res.status(404).json({
        error: 'Record not found.',
        code: err.code,
      });
      return;
    }
  }

  res.status(500).json({
    error: err.message || 'Internal server error occurred',
  });
};
