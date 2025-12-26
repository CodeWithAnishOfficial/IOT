import { Request, Response } from 'express';
import { User, Logger } from '@ev-platform-v1/shared';
import bcrypt from 'bcryptjs';

const logger = new Logger('AdminUserController');

export class AdminUserController {
  
  static async getAllUsers(req: Request, res: Response) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      const skip = (page - 1) * limit;

      const users = await User.find()
        .select('-password') // Assuming password field exists or we just exclude sensitive info
        .sort({ created_at: -1 })
        .skip(skip)
        .limit(limit);

      const total = await User.countDocuments();

      res.json({ 
        error: false, 
        data: users,
        pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit)
        }
      });
    } catch (error: any) {
      logger.error('Error fetching users', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getUserDetails(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await User.findOne({ user_id: parseInt(id) });
      if (!user) return res.status(404).json({ error: true, message: 'User not found' });
      res.json({ error: false, data: user });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async toggleBlockUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { status } = req.body; // true = active, false = blocked

      const user = await User.findOneAndUpdate(
        { user_id: parseInt(id) },
        { status: status },
        { new: true }
      );
      
      if (!user) return res.status(404).json({ error: true, message: 'User not found' });
      
      res.json({ error: false, message: `User ${status ? 'unblocked' : 'blocked'}`, data: user });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async createUser(req: Request, res: Response) {
    try {
      const { email_id, username, phone_no, role_id, rfid_tag, status, password, wallet_bal } = req.body;
      
      if (!email_id) return res.status(400).json({ error: true, message: 'Email ID is required' });

      const existingUser = await User.findOne({ email_id });
      if (existingUser) return res.status(400).json({ error: true, message: 'User with this email already exists' });

      const lastUser = await User.findOne().sort({ user_id: -1 });
      const newUserId = lastUser ? lastUser.user_id + 1 : 1;

      const hashedPassword = password ? await bcrypt.hash(password, 10) : undefined;

      const user = await User.create({
        user_id: newUserId,
        email_id,
        username,
        phone_no,
        password: hashedPassword,
        role_id: role_id || 5, // Default to User
        rfid_tag: rfid_tag || undefined,
        status: status !== undefined ? status : true,
        wallet_bal: wallet_bal || 0
      });

      res.status(201).json({ error: false, message: 'User created successfully', data: user });
    } catch (error: any) {
      logger.error('CreateUser error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async updateUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { email_id, username, phone_no, role_id, rfid_tag, status, wallet_bal, password } = req.body;

      // Build update object
      const updateData: any = { updated_at: new Date() };
      if (email_id) updateData.email_id = email_id;
      if (username) updateData.username = username;
      if (phone_no) updateData.phone_no = phone_no;
      if (role_id) updateData.role_id = role_id;
      if (rfid_tag) updateData.rfid_tag = rfid_tag;
      if (status !== undefined) updateData.status = status;
      if (wallet_bal !== undefined) updateData.wallet_bal = wallet_bal;
      if (password) updateData.password = await bcrypt.hash(password, 10);

      const user = await User.findOneAndUpdate(
        { user_id: parseInt(id) },
        { $set: updateData },
        { new: true }
      );

      if (!user) return res.status(404).json({ error: true, message: 'User not found' });

      res.json({ error: false, message: 'User updated successfully', data: user });
    } catch (error: any) {
      logger.error('UpdateUser error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async deleteUser(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const user = await User.findOneAndDelete({ user_id: parseInt(id) });
      
      if (!user) return res.status(404).json({ error: true, message: 'User not found' });

      res.json({ error: false, message: 'User deleted successfully' });
    } catch (error: any) {
      logger.error('DeleteUser error', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
