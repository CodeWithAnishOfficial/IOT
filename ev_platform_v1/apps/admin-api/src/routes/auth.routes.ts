import { Router } from 'express';
import { AdminAuthController } from '../controllers/auth.controller';

const router = Router();

// Route: POST /auth/login
// Description: Admin login
router.post('/login', AdminAuthController.login);

export default router;
