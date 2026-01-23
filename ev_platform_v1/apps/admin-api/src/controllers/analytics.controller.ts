import { Request, Response } from 'express';
import { User, ChargingSession, Charger, Logger } from '@ev-platform-v1/shared';
import mongoose from 'mongoose';

const logger = new Logger('AnalyticsController');

export class AnalyticsController {
  // User Analytics
  static async getUserAnalytics(req: Request, res: Response) {
    try {
      // 1. Total Users
      const totalUsers = await User.countDocuments();

      // 2. Users by Role (Aggregation)
      const usersByRole = await User.aggregate([
        { $group: { _id: "$role_id", count: { $sum: 1 } } }
      ]);
      // Map role_ids to names (optional, can be done in frontend or here)
      // Assuming 1: Super Admin, 2: Admin, 3: Station Manager, 4: Support, 5: User

      // 3. User Growth (Last 6 months)
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
      
      const userGrowth = await User.aggregate([
        { $match: { created_at: { $gte: sixMonthsAgo } } },
        { 
          $group: { 
            _id: { $dateToString: { format: "%Y-%m", date: "$created_at" } },
            count: { $sum: 1 }
          }
        },
        { $sort: { _id: 1 } }
      ]);

      // 4. Active vs Blocked Users
      const userStatus = await User.aggregate([
        { $group: { _id: "$status", count: { $sum: 1 } } }
      ]);

      res.json({
        error: false,
        data: {
          totalUsers,
          usersByRole,
          userGrowth,
          userStatus
        }
      });
    } catch (error: any) {
      logger.error('Error fetching user analytics', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  // Charger Analytics
  static async getChargerAnalytics(req: Request, res: Response) {
    try {
      // 1. Total Chargers
      const totalChargers = await Charger.countDocuments();

      // 2. Charger Status Distribution
      const chargerStatus = await Charger.aggregate([
        { $group: { _id: "$status", count: { $sum: 1 } } }
      ]);

      // 3. Total Energy Consumed (All time)
      const totalEnergyResult = await ChargingSession.aggregate([
        { $group: { _id: null, totalEnergy: { $sum: "$unit_consumed" } } }
      ]);
      const totalEnergy = totalEnergyResult.length > 0 ? totalEnergyResult[0].totalEnergy : 0;

      // 4. Charging Sessions Over Time (Last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const sessionsTrend = await ChargingSession.aggregate([
        { $match: { start_time: { $gte: thirtyDaysAgo } } },
        {
          $group: {
            _id: { $dateToString: { format: "%Y-%m-%d", date: "$start_time" } },
            count: { $sum: 1 },
            energy: { $sum: "$unit_consumed" }
          }
        },
        { $sort: { _id: 1 } }
      ]);

      // 5. Total Revenue (based on price in sessions)
      const totalRevenueResult = await ChargingSession.aggregate([
          { $group: { _id: null, totalRevenue: { $sum: "$price" } } }
      ]);
      const totalRevenue = totalRevenueResult.length > 0 ? totalRevenueResult[0].totalRevenue : 0;

      res.json({
        error: false,
        data: {
            totalChargers,
            chargerStatus,
            totalEnergy,
            totalRevenue,
            sessionsTrend
        }
      });

    } catch (error: any) {
      logger.error('Error fetching charger analytics', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  // Specific User Analytics
  static async getUserDetailAnalytics(req: Request, res: Response) {
    try {
      const { id } = req.params;
      
      // Try to find user by ID or Email
      let query: any = {};
      // Check if it's a number (user_id) or email
      if (!isNaN(Number(id))) {
        query = { user_id: Number(id) };
      } else if (id.includes('@')) {
        query = { email_id: id };
      } else {
        // Fallback or assume it might be Object ID if valid, or just fail
         if (mongoose.Types.ObjectId.isValid(id)) {
            query = { _id: id };
         } else {
             // If not a number and not an email, maybe it is a username? 
             query = { username: id };
         }
      }

      const user = await User.findOne(query);
      if (!user) {
        return res.status(404).json({ error: true, message: 'User not found' });
      }

      // User Stats
      const stats = await ChargingSession.aggregate([
        { $match: { user_id: user.user_id } },
        { 
          $group: { 
            _id: null, 
            totalSessions: { $sum: 1 },
            totalEnergy: { $sum: "$unit_consumed" },
            totalSpent: { $sum: "$price" },
            lastSessionDate: { $max: "$start_time" }
          } 
        }
      ]);

      const userStats = stats.length > 0 ? stats[0] : {
        totalSessions: 0,
        totalEnergy: 0,
        totalSpent: 0,
        lastSessionDate: null
      };

      // Monthly Usage (Last 6 Months)
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

      const usageHistory = await ChargingSession.aggregate([
        { 
          $match: { 
            user_id: user.user_id,
            start_time: { $gte: sixMonthsAgo }
          } 
        },
        { 
          $group: { 
            _id: { $dateToString: { format: "%Y-%m", date: "$start_time" } },
            sessions: { $sum: 1 },
            energy: { $sum: "$unit_consumed" },
            spent: { $sum: "$price" }
          } 
        },
        { $sort: { _id: 1 } }
      ]);

      res.json({
        error: false,
        data: {
          user: {
            user_id: user.user_id,
            username: user.username,
            email: user.email_id,
            phone_no: user.phone_no,
            wallet_bal: user.wallet_bal,
            role_id: user.role_id,
            rfid_tag: user.rfid_tag,
            status: user.status,
            created_at: user.created_at
          },
          stats: userStats,
          history: usageHistory
        }
      });

    } catch (error: any) {
      logger.error('Error fetching specific user analytics', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
