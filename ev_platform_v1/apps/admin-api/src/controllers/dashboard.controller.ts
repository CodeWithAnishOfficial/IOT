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
}
