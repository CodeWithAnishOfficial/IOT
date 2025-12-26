import { Router } from 'express';
import { DashboardController } from '../controllers/dashboard.controller';

const router = Router();

router.get('/stats', DashboardController.getStats);
router.get('/analytics', DashboardController.getAnalytics);
router.get('/recent-activity', DashboardController.getRecentActivity);

export default router;
