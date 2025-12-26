import { Router } from 'express';
import { RoleController } from '../controllers/role.controller';

const router = Router();

// Role management routes
// GET /roles/list - List all roles
router.get('/list', RoleController.getAllRoles);

// POST /roles/create - Create a new role
router.post('/create', RoleController.createRole);

// PUT /roles/:id/update - Update role details
router.put('/:id/update', RoleController.updateRole);

// DELETE /roles/:id/delete - Delete a role
router.delete('/:id/delete', RoleController.deleteRole);

export default router;
