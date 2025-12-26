import { Router } from 'express';
import { GatewayController } from '../controllers/gateway.controller';

const router = Router();

router.get('/health', GatewayController.healthCheck);
router.get('/metrics', GatewayController.getMetrics);

export default router;
