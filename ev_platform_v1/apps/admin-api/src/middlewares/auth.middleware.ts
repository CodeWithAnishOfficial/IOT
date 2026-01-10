import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'default_secret';

export const authMiddleware = (req: Request, res: Response, next: NextFunction) => {
  let token = req.headers.authorization?.split(' ')[1];

  if (!token && req.query.token) {
      token = req.query.token as string;
  }

  if (!token) {
    return res.status(401).json({ error: true, message: 'Unauthorized' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET, { ignoreExpiration: true });
    // @ts-ignore
    req.user = decoded;
    next();
  } catch (error: any) {
    console.error(`Auth Middleware Error: ${error.message}`);
    return res.status(401).json({ error: true, message: 'Invalid token' });
  }
};
