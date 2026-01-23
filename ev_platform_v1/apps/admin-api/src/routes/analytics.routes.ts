import { Router } from 'express';
import { AnalyticsController } from '../controllers/analytics.controller';

const router = Router();

// Route: GET /analytics/users
// Description: Get user analytics data
router.get('/users', AnalyticsController.getUserAnalytics);

// Route: GET /analytics/chargers
// Description: Get charger analytics data
router.get('/chargers', AnalyticsController.getChargerAnalytics);

// Route: GET /analytics/users/:id
// Description: Get analytics for a specific user
router.get('/users/:id', AnalyticsController.getUserDetailAnalytics);

export default router;
