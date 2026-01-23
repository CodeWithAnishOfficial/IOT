"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminSavedTripController = void 0;
const SavedTrip_1 = __importDefault(require("../models/SavedTrip"));
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('AdminSavedTripController');
class AdminSavedTripController {
    static async getAllSavedTrips(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 20;
            const skip = (page - 1) * limit;
            const { user_id, trip_id } = req.query;
            const query = {};
            if (user_id) {
                const numId = Number(user_id);
                if (!isNaN(numId)) {
                    query.user_id = { $in: [user_id, numId] };
                }
                else {
                    query.user_id = user_id;
                }
            }
            if (trip_id)
                query.trip_id = trip_id;
            const trips = await SavedTrip_1.default.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit);
            const total = await SavedTrip_1.default.countDocuments(query);
            res.json({
                error: false,
                data: trips,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            });
        }
        catch (error) {
            logger.error('Error fetching saved trips', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getSavedTripDetails(req, res) {
        try {
            const { id } = req.params;
            // id could be trip_id (number) or _id (string)
            const numId = Number(id);
            const query = !isNaN(numId) ? { trip_id: numId } : { _id: id };
            const trip = await SavedTrip_1.default.findOne(query);
            if (!trip)
                return res.status(404).json({ error: true, message: 'Trip not found' });
            res.json({ error: false, data: trip });
        }
        catch (error) {
            logger.error('Error fetching saved trip details', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.AdminSavedTripController = AdminSavedTripController;
//# sourceMappingURL=saved_trip.controller.js.map