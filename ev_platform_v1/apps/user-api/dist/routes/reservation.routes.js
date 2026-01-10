"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const shared_1 = require("@ev-platform-v1/shared");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
const logger = new shared_1.Logger('ReservationController');
const redis = shared_1.RedisService.getInstance();
router.use(auth_middleware_1.authMiddleware);
// Route: POST /reservations/create
// Description: Create a new reservation for a connector
router.post('/create', async (req, res) => {
    try {
        const { charger_id, connector_id, expiry_minutes = 15 } = req.body;
        // @ts-ignore
        const userId = req.user.user_id;
        // Check if station exists and connector is available (naive check)
        const station = await shared_1.Charger.findOne({ charger_id });
        if (!station)
            return res.status(404).json({ error: true, message: 'Station not found' });
        // In production, we should check if there are overlapping reservations or if connector is currently charging.
        // For now, we trust the station to Reject if busy.
        const reservationId = Math.floor(Date.now() / 1000); // Simple ID
        const expiryDate = new Date(Date.now() + expiry_minutes * 60000);
        // Create Reservation Record
        const reservation = await shared_1.Reservation.create({
            reservation_id: reservationId,
            charger_id,
            connector_id,
            user_id: Number(userId),
            expiry_date: expiryDate,
            status: 'Pending'
        });
        // Send ReserveNow command
        // Payload for OCPP 1.6 ReserveNow: { connectorId, expiryDate, idTag, reservationId, parentIdTag? }
        const payload = {
            connectorId: connector_id,
            expiryDate: expiryDate.toISOString(),
            idTag: userId, // Using email as tag for now, ideally an RFID tag
            reservationId: reservationId
        };
        await redis.sendCommand(charger_id, 'ReserveNow', payload);
        res.json({ error: false, message: 'Reservation request sent', data: reservation });
    }
    catch (error) {
        logger.error('Error creating reservation', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: GET /reservations/upcoming
// Description: Get the next upcoming reservation
router.get('/upcoming', async (req, res) => {
    try {
        // @ts-ignore
        const userId = req.user.user_id;
        const upcoming = await shared_1.Reservation.findOne({
            user_id: Number(userId),
            expiry_date: { $gt: new Date() }, // Not expired
            status: 'Pending' // Only pending reservations
        }).sort({ expiry_date: 1 }); // Earliest first
        res.json({ error: false, data: upcoming });
    }
    catch (error) {
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: GET /reservations/list
// Description: List all reservations for the current user
router.get('/list', async (req, res) => {
    try {
        // @ts-ignore
        const userId = req.user.user_id;
        const reservations = await shared_1.Reservation.find({ user_id: Number(userId) }).sort({ created_at: -1 });
        res.json({ error: false, data: reservations });
    }
    catch (error) {
        res.status(500).json({ error: true, message: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=reservation.routes.js.map