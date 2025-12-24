import { Router } from 'express';
import { AdminUserController } from '../controllers/user.controller';

const router = Router();

router.get('/', AdminUserController.getAllUsers);
router.get('/:id', AdminUserController.getUserDetails);
router.put('/:id/status', AdminUserController.toggleBlockUser);

export default router;
