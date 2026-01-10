"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DashboardController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('DashboardController');
class DashboardController {
    static async getStats(req, res) {
        try {
            const totalUsers = await shared_1.User.countDocuments();
            const onlineStations = await shared_1.Charger.countDocuments({ status: 'online' });
            const totalStations = await shared_1.Charger.countDocuments();
            const activeSessions = await shared_1.ChargingSession.countDocuments({ status: true });
            // Revenue aggregation
            const revenueStats = await shared_1.WalletTransaction.aggregate([
                { $match: { type: 'debit', source: 'charging_session' } },
                { $group: { _id: null, totalRevenue: { $sum: '$amount' } } }
            ]);
            // Energy aggregation
            const energyStats = await shared_1.ChargingSession.aggregate([
                { $group: { _id: null, totalEnergy: { $sum: '$unit_consumed' } } }
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
        }
        catch (error) {
            logger.error('Error fetching dashboard stats', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getAnalytics(req, res) {
        try {
            const last7Days = new Date();
            last7Days.setDate(last7Days.getDate() - 7);
            // Daily Revenue (Last 7 Days)
            const dailyRevenue = await shared_1.WalletTransaction.aggregate([
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
            const dailyEnergy = await shared_1.ChargingSession.aggregate([
                {
                    $match: {
                        createdAt: { $gte: last7Days }
                    }
                },
                {
                    $group: {
                        _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
                        energy: { $sum: "$unit_consumed" }
                    }
                },
                { $sort: { _id: 1 } }
            ]);
            // Station Status Distribution
            const stationStatus = await shared_1.Charger.aggregate([
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
        }
        catch (error) {
            logger.error('Error fetching dashboard analytics', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getRecentActivity(req, res) {
        try {
            const recentSessions = await shared_1.ChargingSession.find()
                .sort({ createdAt: -1 })
                .limit(5)
                .populate('user_id', 'username email_id')
                .populate('station_id', 'name');
            res.json({
                error: false,
                data: recentSessions
            });
        }
        catch (error) {
            logger.error('Error fetching recent activity', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.DashboardController = DashboardController;
//# sourceMappingURL=dashboard.controller.js.map