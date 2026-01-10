"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const role_controller_1 = require("../controllers/role.controller");
const router = (0, express_1.Router)();
// Role management routes
// GET /roles/list - List all roles
router.get('/list', role_controller_1.RoleController.getAllRoles);
// POST /roles/create - Create a new role
router.post('/create', role_controller_1.RoleController.createRole);
// PUT /roles/:id/update - Update role details
router.put('/:id/update', role_controller_1.RoleController.updateRole);
// DELETE /roles/:id/delete - Delete a role
router.delete('/:id/delete', role_controller_1.RoleController.deleteRole);
exports.default = router;
//# sourceMappingURL=role.routes.js.map