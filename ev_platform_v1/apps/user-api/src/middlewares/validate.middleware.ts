import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodError } from 'zod';

export const validate = (schema: AnyZodObject) => (req: Request, res: Response, next: NextFunction) => {
  try {
    schema.parse({
      body: req.body,
      query: req.query,
      params: req.params,
    });
    next();
  } catch (error) {
    if (error instanceof ZodError) {
      return res.status(400).json({
        error: true,
        message: 'Validation failed',
        details: error.errors.map(e => ({ path: e.path, message: e.message }))
      });
    }
    return res.status(500).json({ error: true, message: 'Internal Server Error' });
  }
};
