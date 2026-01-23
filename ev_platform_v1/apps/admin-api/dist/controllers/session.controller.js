"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminSessionController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('AdminSessionController');
class AdminSessionController {
    static async getAllSessions(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 20;
            const skip = (page - 1) * limit;
            const { user_id, charger_id, status, start_date, end_date } = req.query;
            const query = {};
            if (user_id) {
                const numId = Number(user_id);
                if (!isNaN(numId)) {
                    // Support both string and number for Mixed type user_id
                    query.user_id = { $in: [user_id, numId] };
                }
                else {
                    query.user_id = user_id;
                }
            }
            if (charger_id)
                query.charger_id = charger_id;
            if (status)
                query.status = status === 'true';
            if (start_date && end_date) {
                query.start_time = { $gte: new Date(start_date), $lte: new Date(end_date) };
            }
            const sessions = await shared_1.ChargingSession.find(query)
                .sort({ start_time: -1 })
                .skip(skip)
                .limit(limit);
            const total = await shared_1.ChargingSession.countDocuments(query);
            res.json({
                error: false,
                data: sessions,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            });
        }
        catch (error) {
            logger.error('Error fetching sessions', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getSessionDetails(req, res) {
        try {
            const { id } = req.params;
            const sessionId = parseInt(id);
            if (isNaN(sessionId)) {
                return res.status(400).json({ error: true, message: 'Invalid session ID' });
            }
            const session = await shared_1.ChargingSession.findOne({ session_id: sessionId });
            if (!session)
                return res.status(404).json({ error: true, message: 'Session not found' });
            res.json({ error: false, data: session });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.AdminSessionController = AdminSessionController;
//# sourceMappingURL=session.controller.js.map