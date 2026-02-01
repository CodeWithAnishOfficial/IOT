"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const shared_1 = require("@ev-platform-v1/shared");
(0, shared_1.initTracing)('user-api');
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const shared_2 = require("@ev-platform-v1/shared");
const dotenv_1 = __importDefault(require("dotenv"));
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const wallet_routes_1 = __importDefault(require("./routes/wallet.routes"));
const search_routes_1 = __importDefault(require("./routes/search.routes"));
const profile_routes_1 = __importDefault(require("./routes/profile.routes"));
const sse_routes_1 = __importDefault(require("./routes/sse.routes"));
const reservation_routes_1 = __importDefault(require("./routes/reservation.routes"));
const vehicle_routes_1 = __importDefault(require("./routes/vehicle.routes"));
const support_routes_1 = __importDefault(require("./routes/support.routes"));
const charging_routes_1 = __importDefault(require("./routes/charging.routes"));
const commercial_routes_1 = __importDefault(require("./routes/commercial.routes"));
const saved_trips_routes_1 = __importDefault(require("./routes/saved_trips.routes"));
const billing_service_1 = require("./services/billing.service");
const sse_service_1 = require("./services/sse.service");
const prom_client_1 = __importDefault(require("prom-client"));
const http_1 = require("http");
const ws_1 = require("ws");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const url_1 = __importDefault(require("url"));
dotenv_1.default.config();
const logger = new shared_2.Logger('User-API');
const app = (0, express_1.default)();
const PORT = process.env.USER_API_PORT ? parseInt(process.env.USER_API_PORT) : 3001;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://192.168.1.8:27017/ev_platform';
const JWT_SECRET = process.env.JWT_SECRET || 'ev-platform-secret-key';
// Prometheus Metrics
const collectDefaultMetrics = prom_client_1.default.collectDefaultMetrics;
collectDefaultMetrics({ register: prom_client_1.default.register });
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Routes
app.use('/auth', auth_routes_1.default);
app.use('/wallet', wallet_routes_1.default);
app.use('/search', search_routes_1.default);
app.use('/profile', profile_routes_1.default);
app.use('/events', sse_routes_1.default);
app.use('/reservations', reservation_routes_1.default);
app.use('/vehicles', vehicle_routes_1.default);
app.use('/support', support_routes_1.default);
app.use('/charging', charging_routes_1.default);
app.use('/commercial', commercial_routes_1.default);
app.use('/saved-trips', saved_trips_routes_1.default);
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prom_client_1.default.register.contentType);
    res.end(await prom_client_1.default.register.metrics());
});
app.get('/health', (req, res) => {
    res.json({ status: 'UP', service: 'User-API' });
});
const start = async () => {
    try {
        await shared_2.Database.getInstance().connect(MONGO_URI);
        // Connect to RabbitMQ and start consumers
        const rabbit = shared_2.RabbitMQService.getInstance();
        await rabbit.connect();
        // CDR Processing
        await rabbit.consume('cdr_events', async (msg) => {
            const updatedSession = await billing_service_1.BillingService.processCDR(msg);
            // Also notify user about completed session
            const targetUser = msg.userEmail || msg.userId;
            if (targetUser) {
                sse_service_1.SseService.sendToUser(targetUser, 'session_completed', updatedSession || msg);
            }
        });
        // Station Status Updates (assuming queue exists)
        await rabbit.consume('station_status_events', async (msg) => {
            // Broadcast station status to all users looking at map
            sse_service_1.SseService.broadcast('station_status', msg);
        });
        // Session Started
        await rabbit.consume('session_started', async (msg) => {
            if (msg.userId) {
                sse_service_1.SseService.sendToUser(msg.userId, 'session_started', msg);
            }
        });
        // Charging Progress
        await rabbit.consume('charging_progress', async (msg) => {
            if (msg.userId) {
                sse_service_1.SseService.sendToUser(msg.userId, 'charging_progress', msg);
            }
        });
        logger.info('Started consuming events');
        // Start WebSocket Heartbeat
        sse_service_1.SseService.startHeartbeat(30000);
        // Create HTTP Server
        const httpServer = (0, http_1.createServer)(app);
        // Setup WebSocket Server
        const wss = new ws_1.WebSocketServer({ server: httpServer });
        wss.on('connection', (ws, req) => {
            const parameters = url_1.default.parse(req.url || '', true);
            const token = parameters.query.token;
            let userId = 'guest_' + Math.random().toString(36).substr(2, 9);
            if (token) {
                try {
                    // Try to verify, but don't block if it fails (e.g. expired)
                    // If verification works, great.
                    const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
                    userId = decoded.email_id;
                }
                catch (err) {
                    logger.warn(`WebSocket token invalid/expired for connection, allowing anyway: ${err.message}`);
                    // If verify fails (e.g. expired), try to just decode to get the user ID
                    try {
                        const decoded = jsonwebtoken_1.default.decode(token);
                        if (decoded && decoded.email_id) {
                            userId = decoded.email_id;
                        }
                    }
                    catch (e) {
                        // Keep random guest ID
                    }
                }
            }
            logger.info(`WebSocket connected for user: ${userId}`);
            sse_service_1.SseService.addWsClient(ws, userId);
            // Send initial ping or welcome
            ws.send(JSON.stringify({ event: 'connected', message: 'WebSocket connection established' }));
        });
        httpServer.listen(PORT, () => {
            logger.info(`User API running on port ${PORT} (HTTP + WS)`);
        });
    }
    catch (error) {
        logger.error('Failed to start User API', error);
        process.exit(1);
    }
};
start();
//# sourceMappingURL=index.js.map