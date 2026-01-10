"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const support_controller_1 = require("../controllers/support.controller");
const router = (0, express_1.Router)();
router.get('/', support_controller_1.AdminSupportController.getAllTickets);
router.put('/:id/status', support_controller_1.AdminSupportController.updateTicketStatus);
router.post('/:id/reply', support_controller_1.AdminSupportController.addReply);
exports.default = router;
//# sourceMappingURL=support.routes.js.map