import { Request, Response } from 'express';
import { User, ChargingSession, ChargingStation, WalletTransaction, Logger } from '@ev-platform-v1/shared';

const logger = new Logger('DashboardController');

export class DashboardController {
  
  static async getStats(req: Request, res: Response) {
    try {
      const totalUsers = await User.countDocuments();
      const onlineStations = await ChargingStation.countDocuments({ status: 'online' });
      const totalStations = await ChargingStation.countDocuments();
      const activeSessions = await ChargingSession.countDocuments({ status: 'active' });

      // Revenue aggregation
      const revenueStats = await WalletTransaction.aggregate([
        { $match: { type: 'debit', source: 'charging_session' } },
        { $group: { _id: null, totalRevenue: { $sum: '$amount' } } }
      ]);

      // Energy aggregation
      const energyStats = await ChargingSession.aggregate([
        { $group: { _id: null, totalEnergy: { $sum: '$total_energy' } } }
      ]);

      res.json({
        error: false,
        data: {
          users: { total: totalUsers },
          stations: { 
            total: totalStations, 
            online: onlineStations,
            offline: totalStations - onlineStations 
          },
          sessions: { active: activeSessions },
          financials: {
            total_revenue: revenueStats[0]?.totalRevenue || 0,
            total_energy_kwh: (energyStats[0]?.totalEnergy || 0) / 1000
          }
        }
      });
    } catch (error: any) {
      logger.error('Error fetching dashboard stats', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getAnalytics(req: Request, res: Response) {
    try {
      const last7Days = new Date();
      last7Days.setDate(last7Days.getDate() - 7);

      // Daily Revenue (Last 7 Days)
      const dailyRevenue = await WalletTransaction.aggregate([
        { 
          $match: { 
            type: 'debit', 
            source: 'charging_session',
            createdAt: { $gte: last7Days }
          } 
        },
        {
          $group: {
            _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
            revenue: { $sum: "$amount" }
          }
        },
        { $sort: { _id: 1 } }
      ]);

      // Daily Energy (Last 7 Days)
      const dailyEnergy = await ChargingSession.aggregate([
        {
          $match: {
            createdAt: { $gte: last7Days }
          }
        },
        {
          $group: {
            _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
            energy: { $sum: "$total_energy" }
          }
        },
        { $sort: { _id: 1 } }
      ]);

      // Station Status Distribution
      const stationStatus = await ChargingStation.aggregate([
        {
          $group: {
            _id: "$status",
            count: { $sum: 1 }
          }
        }
      ]);

      res.json({
        error: false,
        data: {
          revenue_chart: dailyRevenue,
          energy_chart: dailyEnergy,
          station_distribution: stationStatus
        }
      });
    } catch (error: any) {
      logger.error('Error fetching dashboard analytics', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }

  static async getRecentActivity(req: Request, res: Response) {
    try {
      const recentSessions = await ChargingSession.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('user_id', 'username email_id')
        .populate('station_id', 'name');

      res.json({
        error: false,
        data: recentSessions
      });
    } catch (error: any) {
      logger.error('Error fetching recent activity', error);
      res.status(500).json({ error: true, message: error.message });
    }
  }
}
