"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SiteController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('SiteController');
class SiteController {
    static async createSite(req, res) {
        try {
            const site = await shared_1.Site.create(req.body);
            res.status(201).json({ error: false, message: 'Site created', data: site });
        }
        catch (error) {
            logger.error('Error creating site', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getAllSites(req, res) {
        try {
            const sites = await shared_1.Site.find().sort({ created_at: -1 });
            res.json({ error: false, data: sites });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getSiteById(req, res) {
        try {
            const { id } = req.params;
            const site = await shared_1.Site.findById(id);
            if (!site)
                return res.status(404).json({ error: true, message: 'Site not found' });
            // Optionally fetch all chargers at this site
            const chargers = await shared_1.Charger.find({ site_id: id });
            res.json({ error: false, data: { ...site.toObject(), chargers } });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async updateSite(req, res) {
        try {
            const { id } = req.params;
            const site = await shared_1.Site.findByIdAndUpdate(id, req.body, { new: true });
            if (!site)
                return res.status(404).json({ error: true, message: 'Site not found' });
            res.json({ error: false, message: 'Site updated', data: site });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async deleteSite(req, res) {
        try {
            const { id } = req.params;
            // Check if there are chargers linked
            const chargersCount = await shared_1.Charger.countDocuments({ site_id: id });
            if (chargersCount > 0) {
                return res.status(400).json({ error: true, message: `Cannot delete site. It has ${chargersCount} chargers linked.` });
            }
            await shared_1.Site.findByIdAndDelete(id);
            res.json({ error: false, message: 'Site deleted' });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async uploadImage(req, res) {
        try {
            if (!req.file) {
                return res.status(400).json({ error: true, message: 'No file uploaded' });
            }
            const filePath = `/uploads/images/${req.file.filename}`;
            res.json({ error: false, message: 'File uploaded', url: filePath });
        }
        catch (error) {
            logger.error('Error uploading file', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.SiteController = SiteController;
//# sourceMappingURL=site.controller.js.map