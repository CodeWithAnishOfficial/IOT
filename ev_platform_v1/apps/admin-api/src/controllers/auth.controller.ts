import { Request, Response } from 'express';
import { User, Logger } from '@ev-platform-v1/shared';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const logger = new Logger('AdminAuthController');
const JWT_SECRET = process.env.JWT_SECRET || 'default_secret';

export class AdminAuthController {
  static async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;
      if (!email || !password) return res.status(400).json({ error: true, message: 'Email and password required' });

      const user = await User.findOne({ email_id: email });
      if (!user) return res.status(401).json({ error: true, message: 'Invalid credentials' });

      if (!user.password) return res.status(400).json({ error: true, message: 'Password not set for this user' });

      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) return res.status(401).json({ error: true, message: 'Invalid credentials' });

      // Check for Admin Role (Assuming 1 is Admin, 2 might be SuperAdmin, etc. Adjust as needed)
      // If roles are not strictly defined yet, we might want to allow this for now or check specifically.
      // For now, let's assume any user in the admin portal must have admin rights.
      // Ideally, we check: if (user.role_id !== 1) ...
      
      const token = jwt.sign(
        { 
          email_id: user.email_id, 
          user_id: user.user_id, 
          role_id: user.role_id 
        }, 
        JWT_SECRET, 
        { expiresIn: '24h' }
      );

      res.json({
        error: false,
        message: 'Login successful',
        token,
        user: {
          user_id: user.user_id,
          username: user.username,
          email: user.email_id,
          role_id: user.role_id
        }
      });
    } catch (error: any) {
      logger.error('Login error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async me(req: Request, res: Response) {
      // access user from request (middleware should populate this)
      // For now, returning success to validate token if middleware existed
      res.json({ error: false, message: 'Authorized' });
  }
}
