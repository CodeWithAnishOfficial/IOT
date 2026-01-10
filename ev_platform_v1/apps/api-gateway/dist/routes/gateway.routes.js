"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const gateway_controller_1 = require("../controllers/gateway.controller");
const router = (0, express_1.Router)();
router.get('/health', gateway_controller_1.GatewayController.healthCheck);
router.get('/metrics', gateway_controller_1.GatewayController.getMetrics);
exports.default = router;
//# sourceMappingURL=gateway.routes.js.map