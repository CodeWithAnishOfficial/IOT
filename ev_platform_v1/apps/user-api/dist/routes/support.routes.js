"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const support_controller_1 = require("../controllers/support.controller");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const router = (0, express_1.Router)();
router.use(auth_middleware_1.authMiddleware);
// Route: POST /support/create
// Description: Create a new support ticket
router.post('/create', support_controller_1.SupportController.createTicket);
// Route: GET /support/list
// Description: Get all tickets created by the user
router.get('/list', support_controller_1.SupportController.getMyTickets);
// Route: POST /support/:id/reply
// Description: Add a reply to a support ticket
router.post('/:id/reply', support_controller_1.SupportController.addReply);
exports.default = router;
//# sourceMappingURL=support.routes.js.map