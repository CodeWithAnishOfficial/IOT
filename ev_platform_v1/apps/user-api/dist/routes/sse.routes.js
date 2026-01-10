"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_middleware_1 = require("../middlewares/auth.middleware");
const sse_service_1 = require("../services/sse.service");
const router = (0, express_1.Router)();
router.get('/connect', auth_middleware_1.authMiddleware, (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();
    // @ts-ignore
    const userId = req.user.email_id;
    sse_service_1.SseService.addClient(res, userId);
    // Send initial ping
    res.write('event: connected\n');
    res.write(`data: ${JSON.stringify({ message: 'Connected to SSE' })}\n\n`);
});
exports.default = router;
//# sourceMappingURL=sse.routes.js.map