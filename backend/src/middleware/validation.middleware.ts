import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export const validateBody = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const errors = err.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        const summary = errors.map((e) => `${e.field ? e.field + ': ' : ''}${e.message}`).join(', ');
        res.status(400).json({
          error: 'Validation failed',
          message: `Validation failed (${summary})`,
          details: errors,
        });
        return;
      }
      next(err);
    }
  };
};

export const validateQuery = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.query = schema.parse(req.query);
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const errors = err.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        }));
        const summary = errors.map((e) => `${e.field ? e.field + ': ' : ''}${e.message}`).join(', ');
        res.status(400).json({
          error: 'Validation failed',
          message: `Validation failed (${summary})`,
          details: errors,
        });
        return;
      }
      next(err);
    }
  };
};
