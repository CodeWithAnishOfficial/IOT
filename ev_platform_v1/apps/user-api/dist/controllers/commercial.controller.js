"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CommercialController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('CommercialController');
class CommercialController {
    // Add a charger for commercialization
    static async addCharger(req, res) {
        logger.info(`Received addCharger request. Body: ${JSON.stringify(req.body)}`);
        let createdSiteId = null;
        try {
            const userId = req.user.user_id;
            const { charger_id, name, location, price_per_kwh, connectors, vendor, modelName, serial_number } = req.body;
            // Basic validation
            if (!charger_id || !price_per_kwh) {
                return res.status(400).json({ error: true, message: 'charger_id and price_per_kwh are required' });
            }
            // Check if charger exists
            const existing = await shared_1.Charger.findOne({ charger_id });
            if (existing) {
                return res.status(400).json({ error: true, message: 'Charger ID already exists' });
            }
            // Create a Site (Station) automatically for this charger
            // In commercial/peer-to-peer, usually the location is the home/office of the user.
            const siteName = name ? `${name} Station` : `User Station ${charger_id}`;
            const newSite = await shared_1.Site.create({
                name: siteName,
                address: location?.address || 'Address not provided',
                city: 'Unknown', // Default as we might not have it parsed
                country: 'India',
                location: {
                    lat: location?.lat || 0,
                    lng: location?.lng || 0
                },
                contact_number: '', // Can be updated later
                images: [],
                facilities: ['User Provided']
            });
            createdSiteId = newSite._id;
            const charger = new shared_1.Charger({
                charger_id,
                name: name || `User Charger ${charger_id}`,
                owner_id: userId,
                is_public: true,
                price_per_kwh,
                location,
                site_id: newSite._id, // Link to the new site
                status: 'offline', // Start offline
                connectors: connectors || [{ connector_id: 1, type: 'Type2', status: 'Available' }],
                vendor,
                modelName,
                serial_number
            });
            await charger.save();
            logger.info(`User ${userId} added commercial charger ${charger_id} with site ${newSite._id}`);
            return res.status(201).json({
                error: false,
                message: 'Charger added successfully',
                data: { charger, site: newSite }
            });
        }
        catch (error) {
            logger.error('Error adding commercial charger', error);
            // Rollback Site creation if Charger creation fails
            if (createdSiteId) {
                try {
                    await shared_1.Site.findByIdAndDelete(createdSiteId);
                    logger.info(`Rolled back site ${createdSiteId} due to charger creation failure`);
                }
                catch (rollbackError) {
                    logger.error(`Error rolling back site ${createdSiteId}`, rollbackError);
                }
            }
            return res.status(500).json({ error: true, message: error.message });
        }
    }
    // Get my commercial chargers
    static async getMyChargers(req, res) {
        try {
            const userId = req.user.user_id;
            // Populate site details
            const chargers = await shared_1.Charger.find({ owner_id: userId }).populate('site_id');
            return res.json({
                error: false,
                message: 'Chargers fetched successfully',
                data: chargers
            });
        }
        catch (error) {
            logger.error('Error fetching my chargers', error);
            return res.status(500).json({ error: true, message: 'Internal server error' });
        }
    }
    // Get analytics (sessions and earnings)
    static async getAnalytics(req, res) {
        try {
            const userId = req.user.user_id;
            // Find chargers owned by user
            const chargers = await shared_1.Charger.find({ owner_id: userId }).select('charger_id');
            const chargerIds = chargers.map(c => c.charger_id);
            if (chargerIds.length === 0) {
                return res.json({
                    error: false,
                    message: 'No chargers found for analytics',
                    data: {
                        total_earnings: 0,
                        total_sessions: 0,
                        total_energy: 0,
                        sessions: []
                    }
                });
            }
            // Find sessions for these chargers
            const sessions = await shared_1.ChargingSession.find({ charger_id: { $in: chargerIds } })
                .sort({ created_date: -1 })
                .limit(100);
            // Aggregate totals
            const stats = await shared_1.ChargingSession.aggregate([
                { $match: { charger_id: { $in: chargerIds }, transactionState: 'Completed' } }, // Only completed transactions count for earnings usually
                {
                    $group: {
                        _id: null,
                        total_earnings: { $sum: '$price' },
                        total_sessions: { $sum: 1 },
                        total_energy: { $sum: '$unit_consumed' }
                    }
                }
            ]);
            const data = stats.length > 0 ? stats[0] : { total_earnings: 0, total_sessions: 0, total_energy: 0 };
            return res.json({
                error: false,
                message: 'Analytics fetched successfully',
                data: {
                    total_earnings: data.total_earnings,
                    total_sessions: data.total_sessions,
                    total_energy: data.total_energy,
                    recent_sessions: sessions
                }
            });
        }
        catch (error) {
            logger.error('Error fetching analytics', error);
            return res.status(500).json({ error: true, message: 'Internal server error' });
        }
    }
    // Get commercial wallet history (earnings only)
    static async getWalletHistory(req, res) {
        try {
            const userId = req.user.user_id;
            const transactions = await shared_1.WalletTransaction.find({
                user_id: userId.toString(),
                source: 'earnings'
            }).sort({ created_at: -1 });
            return res.json({
                error: false,
                message: 'Wallet history fetched successfully',
                data: transactions
            });
        }
        catch (error) {
            logger.error('Error fetching wallet history', error);
            return res.status(500).json({ error: true, message: 'Internal server error' });
        }
    }
}
exports.CommercialController = CommercialController;
//# sourceMappingURL=commercial.controller.js.map