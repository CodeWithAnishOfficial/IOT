"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const analytics_controller_1 = require("../controllers/analytics.controller");
const router = (0, express_1.Router)();
// Route: GET /analytics/users
// Description: Get user analytics data
router.get('/users', analytics_controller_1.AnalyticsController.getUserAnalytics);
// Route: GET /analytics/chargers
// Description: Get charger analytics data
router.get('/chargers', analytics_controller_1.AnalyticsController.getChargerAnalytics);
// Route: GET /analytics/users/:id
// Description: Get analytics for a specific user
router.get('/users/:id', analytics_controller_1.AnalyticsController.getUserDetailAnalytics);
exports.default = router;
//# sourceMappingURL=analytics.routes.js.map