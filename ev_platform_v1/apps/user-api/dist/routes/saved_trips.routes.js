"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const SavedTrip_1 = __importDefault(require("../models/SavedTrip"));
const auth_middleware_1 = require("../middlewares/auth.middleware");
const shared_1 = require("@ev-platform-v1/shared");
const router = (0, express_1.Router)();
const logger = new shared_1.Logger('SavedTripsController');
// Route: POST /saved-trips
// Description: Save a new trip
router.post('/', auth_middleware_1.authMiddleware, async (req, res) => {
    try {
        // @ts-ignore
        const user_id = req.user?.user_id;
        const { name, source, destination, stops } = req.body;
        if (!name || !source || !destination) {
            return res.status(400).json({ error: true, message: 'Name, source, and destination are required' });
        }
        const trip_id = Math.floor(Date.now() / 1000); // Generate simple numeric ID
        const newTrip = await SavedTrip_1.default.create({
            trip_id,
            user_id: Number(user_id),
            name,
            source,
            destination,
            stops: stops || []
        });
        res.json({ error: false, message: 'Trip saved successfully', data: newTrip });
    }
    catch (error) {
        logger.error('Error saving trip', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: GET /saved-trips
// Description: Get all saved trips for the user
router.get('/', auth_middleware_1.authMiddleware, async (req, res) => {
    try {
        // @ts-ignore
        const user_id = req.user?.user_id;
        const trips = await SavedTrip_1.default.find({ user_id: Number(user_id) }).sort({ createdAt: -1 });
        res.json({ error: false, data: trips });
    }
    catch (error) {
        logger.error('Error fetching saved trips', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: DELETE /saved-trips/:id
// Description: Delete a saved trip
router.delete('/:id', auth_middleware_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        // @ts-ignore
        const user_id = req.user?.user_id;
        // Try deleting by numeric trip_id first (if id is numeric)
        let trip;
        if (!isNaN(Number(id))) {
            trip = await SavedTrip_1.default.findOneAndDelete({ trip_id: Number(id), user_id: Number(user_id) });
        }
        // If not found or id wasn't numeric, try _id
        if (!trip) {
            trip = await SavedTrip_1.default.findOneAndDelete({ _id: id, user_id: Number(user_id) });
        }
        if (!trip) {
            return res.status(404).json({ error: true, message: 'Trip not found or unauthorized' });
        }
        res.json({ error: false, message: 'Trip deleted successfully' });
    }
    catch (error) {
        logger.error('Error deleting trip', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=saved_trips.routes.js.map