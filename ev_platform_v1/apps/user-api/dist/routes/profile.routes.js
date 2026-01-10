"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const shared_1 = require("@ev-platform-v1/shared");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const invoice_service_1 = require("../services/invoice.service");
const router = (0, express_1.Router)();
const logger = new shared_1.Logger('ProfileController');
const redis = shared_1.RedisService.getInstance();
router.use(auth_middleware_1.authMiddleware);
// Route: GET /profile/me
// Description: Get current user profile details
router.get('/me', async (req, res) => {
    try {
        // @ts-ignore
        const email = req.user.email_id;
        // Check cache
        const CACHE_KEY = `user:${email}:profile`;
        let user = await redis.get(CACHE_KEY);
        if (!user) {
            user = await shared_1.User.findOne({ email_id: email });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            await redis.set(CACHE_KEY, user, 300); // Cache for 5 mins
        }
        res.json({ error: false, data: user });
    }
    catch (error) {
        logger.error('Error fetching profile', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: PUT /profile/me
// Description: Update current user profile details
router.put('/me', async (req, res) => {
    try {
        // @ts-ignore
        const email = req.user.email_id;
        const { username, phone_no } = req.body;
        const user = await shared_1.User.findOneAndUpdate({ email_id: email }, { $set: { username, phone_no, updated_at: new Date() } }, { new: true });
        // Invalidate cache
        const CACHE_KEY = `user:${email}:profile`;
        await redis.del(CACHE_KEY);
        res.json({ error: false, message: 'Profile updated', data: user });
    }
    catch (error) {
        logger.error('Error updating profile', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: GET /profile/sessions
// Description: Get charging history for the current user
router.get('/sessions', async (req, res) => {
    try {
        // @ts-ignore
        const email = req.user.email_id;
        // Assuming user_id in ChargingSession matches email or some user ID.
        // In startTransaction handler we used idTag as user_id.
        // Ideally we should resolve user_id from tag, but for now querying by user_id field.
        const sessions = await shared_1.ChargingSession.find({ user_id: email }).sort({ start_time: -1 });
        res.json({ error: false, data: sessions });
    }
    catch (error) {
        logger.error('Error fetching sessions', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
// Route: POST /profile/sessions/:id/invoice
// Description: Generate and email invoice for a specific charging session
router.post('/sessions/:id/invoice', async (req, res) => {
    try {
        const { id } = req.params;
        // @ts-ignore
        const email = req.user.email_id;
        const session = await shared_1.ChargingSession.findOne({ session_id: Number(id) });
        if (!session)
            return res.status(404).json({ error: true, message: 'Session not found' });
        const pdfBuffer = await invoice_service_1.InvoiceService.generateInvoice(session);
        await invoice_service_1.InvoiceService.sendInvoiceEmail(email, pdfBuffer, session);
        res.json({ error: false, message: 'Invoice sent to email' });
    }
    catch (error) {
        logger.error('Error sending invoice', error);
        res.status(500).json({ error: true, message: error.message });
    }
});
exports.default = router;
//# sourceMappingURL=profile.routes.js.map