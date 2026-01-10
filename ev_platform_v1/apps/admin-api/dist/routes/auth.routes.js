"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("../controllers/auth.controller");
const router = (0, express_1.Router)();
// Route: POST /auth/login
// Description: Admin login
router.post('/login', auth_controller_1.AdminAuthController.login);
exports.default = router;
//# sourceMappingURL=auth.routes.js.map