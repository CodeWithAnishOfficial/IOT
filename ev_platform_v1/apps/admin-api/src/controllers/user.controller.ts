import { Request, Response } from 'express';
import { User, Logger } from '@ev-platform-v1/shared';

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
      const user = await User.findOne({ user_id: id });
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
        { user_id: id },
        { status: status },
        { new: true }
      );
      
      if (!user) return res.status(404).json({ error: true, message: 'User not found' });
      
      res.json({ error: false, message: `User ${status ? 'unblocked' : 'blocked'}`, data: user });
    } catch (error: any) {
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
