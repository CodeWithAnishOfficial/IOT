"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const mongoose_1 = __importDefault(require("mongoose"));
const logger = new shared_1.Logger('AnalyticsController');
class AnalyticsController {
    // User Analytics
    static async getUserAnalytics(req, res) {
        try {
            // 1. Total Users
            const totalUsers = await shared_1.User.countDocuments();
            // 2. Users by Role (Aggregation)
            const usersByRole = await shared_1.User.aggregate([
                { $group: { _id: "$role_id", count: { $sum: 1 } } }
            ]);
            // Map role_ids to names (optional, can be done in frontend or here)
            // Assuming 1: Super Admin, 2: Admin, 3: Station Manager, 4: Support, 5: User
            // 3. User Growth (Last 6 months)
            const sixMonthsAgo = new Date();
            sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
            const userGrowth = await shared_1.User.aggregate([
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
            const userStatus = await shared_1.User.aggregate([
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
        }
        catch (error) {
            logger.error('Error fetching user analytics', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    // Charger Analytics
    static async getChargerAnalytics(req, res) {
        try {
            // 1. Total Chargers
            const totalChargers = await shared_1.Charger.countDocuments();
            // 2. Charger Status Distribution
            const chargerStatus = await shared_1.Charger.aggregate([
                { $group: { _id: "$status", count: { $sum: 1 } } }
            ]);
            // 3. Total Energy Consumed (All time)
            const totalEnergyResult = await shared_1.ChargingSession.aggregate([
                { $group: { _id: null, totalEnergy: { $sum: "$unit_consumed" } } }
            ]);
            const totalEnergy = totalEnergyResult.length > 0 ? totalEnergyResult[0].totalEnergy : 0;
            // 4. Charging Sessions Over Time (Last 30 days)
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            const sessionsTrend = await shared_1.ChargingSession.aggregate([
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
            const totalRevenueResult = await shared_1.ChargingSession.aggregate([
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
        }
        catch (error) {
            logger.error('Error fetching charger analytics', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    // Specific User Analytics
    static async getUserDetailAnalytics(req, res) {
        try {
            const { id } = req.params;
            // Try to find user by ID or Email
            let query = {};
            // Check if it's a number (user_id) or email
            if (!isNaN(Number(id))) {
                query = { user_id: Number(id) };
            }
            else if (id.includes('@')) {
                query = { email_id: id };
            }
            else {
                // Fallback or assume it might be Object ID if valid, or just fail
                if (mongoose_1.default.Types.ObjectId.isValid(id)) {
                    query = { _id: id };
                }
                else {
                    // If not a number and not an email, maybe it is a username? 
                    query = { username: id };
                }
            }
            const user = await shared_1.User.findOne(query);
            if (!user) {
                return res.status(404).json({ error: true, message: 'User not found' });
            }
            // User Stats
            const stats = await shared_1.ChargingSession.aggregate([
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
            const usageHistory = await shared_1.ChargingSession.aggregate([
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
        }
        catch (error) {
            logger.error('Error fetching specific user analytics', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.AnalyticsController = AnalyticsController;
//# sourceMappingURL=analytics.controller.js.map