import { Request, Response } from 'express';
import { User, Logger } from '@ev-platform-v1/shared';
import { OTPService } from '../services/otp.service';
import { EmailService } from '../services/email.service';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import bcrypt from 'bcryptjs';

const logger = new Logger('AuthController');
const JWT_SECRET = process.env.JWT_SECRET || 'default_secret';
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;

const client = new OAuth2Client(GOOGLE_CLIENT_ID);

export class AuthController {
  static async generateOTP(req: Request, res: Response) {
    try {
      const { email_id } = req.body;
      if (!email_id) return res.status(400).json({ error: true, message: 'Email ID is required' });

      const otp = await OTPService.generateOTP(email_id);
      await EmailService.sendOTP(email_id, otp);

      res.status(200).json({ error: false, message: `OTP sent to ${email_id}` });
    } catch (error: any) {
      logger.error('GenerateOTP error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async initiateRegistration(req: Request, res: Response) {
    try {
      const { email_id } = req.body;
      if (!email_id) return res.status(400).json({ error: true, message: 'Email ID is required' });

      const existingUser = await User.findOne({ email_id });
      if (existingUser) return res.status(400).json({ error: true, message: 'User already exists. Please login.' });

      const otp = await OTPService.generateOTP(email_id);
      await EmailService.sendOTP(email_id, otp);

      res.status(200).json({ error: false, message: `OTP sent to ${email_id} for registration` });
    } catch (error: any) {
      logger.error('InitiateRegistration error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async verifyOTP(req: Request, res: Response) {
    try {
      const { email_id, otp, username, phone_no, password } = req.body;
      if (!email_id || !otp) return res.status(400).json({ error: true, message: 'Email and OTP required' });

      const isValid = OTPService.verifyOTP(email_id, parseInt(otp));
      if (!isValid) return res.status(400).json({ error: true, message: 'Invalid or expired OTP' });

      let user = await User.findOne({ email_id });
      if (!user) {
        // Register new user
        const lastUser = await User.findOne().sort({ user_id: -1 });
        const newUserId = lastUser ? lastUser.user_id + 1 : 1;

        const hashedPassword = password ? await bcrypt.hash(password, 10) : undefined;

        user = await User.create({
          user_id: newUserId,
          email_id,
          username: username || undefined,
          phone_no: phone_no || undefined,
          password: hashedPassword,
          role_id: 5, // User role
          status: true
        });
      }

      const token = jwt.sign({ email_id: user.email_id, user_id: user.user_id, role_id: user.role_id }, JWT_SECRET, { expiresIn: '1d' });

      res.status(200).json({
        error: false,
        message: 'Login successful',
        token,
        data: user
      });
    } catch (error: any) {
      logger.error('VerifyOTP error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async passwordLogin(req: Request, res: Response) {
    try {
      const { email_id, password } = req.body;
      if (!email_id || !password) return res.status(400).json({ error: true, message: 'Email and password required' });

      const user = await User.findOne({ email_id });
      if (!user) return res.status(400).json({ error: true, message: 'User not found' });

      if (!user.password) return res.status(400).json({ error: true, message: 'Password not set. Please login via OTP or Google.' });

      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) return res.status(400).json({ error: true, message: 'Invalid password' });

      const token = jwt.sign({ email_id: user.email_id, user_id: user.user_id, role_id: user.role_id }, JWT_SECRET, { expiresIn: '1d' });

      res.status(200).json({
        error: false,
        message: 'Login successful',
        token,
        data: user
      });
    } catch (error: any) {
      logger.error('PasswordLogin error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async googleSignIn(req: Request, res: Response) {
    try {
      const { idToken } = req.body;
      if (!idToken) return res.status(400).json({ error: true, message: 'Google ID Token required' });

      const ticket = await client.verifyIdToken({
        idToken,
        audience: GOOGLE_CLIENT_ID,
      });

      const payload = ticket.getPayload();
      if (!payload || !payload.email) return res.status(400).json({ error: true, message: 'Invalid Google Token' });

      const { email, name, picture } = payload;

      let user = await User.findOne({ email_id: email });
      if (!user) {
        const lastUser = await User.findOne().sort({ user_id: -1 });
        const newUserId = lastUser ? lastUser.user_id + 1 : 1;

        user = await User.create({
          user_id: newUserId,
          username: name,
          email_id: email,
          role_id: 5,
          status: true
        });
      }

      const token = jwt.sign({ email_id: user.email_id, user_id: user.user_id, role_id: user.role_id }, JWT_SECRET, { expiresIn: '1d' });

      res.status(200).json({
        error: false,
        message: 'Google Login successful',
        token,
        data: user
      });
    } catch (error: any) {
      logger.error('GoogleSignIn error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
