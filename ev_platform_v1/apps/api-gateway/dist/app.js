"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.App = void 0;
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const shared_1 = require("@ev-platform-v1/shared");
const http_proxy_middleware_1 = require("http-proxy-middleware");
const prom_client_1 = __importDefault(require("prom-client"));
const rateLimit_middleware_1 = require("./middlewares/rateLimit.middleware");
const gateway_routes_1 = __importDefault(require("./routes/gateway.routes"));
class App {
    app;
    port;
    logger;
    constructor(port) {
        this.app = (0, express_1.default)();
        this.port = port;
        this.logger = new shared_1.Logger('API-Gateway');
        // Prometheus
        const collectDefaultMetrics = prom_client_1.default.collectDefaultMetrics;
        collectDefaultMetrics({ register: prom_client_1.default.register });
        this.initializeMiddlewares();
        this.initializeRoutes();
    }
    initializeMiddlewares() {
        this.app.use((0, cors_1.default)());
        this.app.use((0, helmet_1.default)());
        this.app.use(rateLimit_middleware_1.limiter);
        // Logging middleware
        this.app.use((req, res, next) => {
            this.logger.info(`${req.method} ${req.url}`);
            next();
        });
    }
    initializeRoutes() {
        // Gateway Routes
        this.app.use('/', gateway_routes_1.default);
        // Proxy to User API
        const userApiUrl = process.env.USER_API_URL || 'http://64.227.181.90:3001';
        const userServices = [
            '/auth', '/wallet', '/profile', '/search',
            '/reservations', '/events', '/vehicles', '/support', '/charging',
            '/saved-trips'
        ];
        userServices.forEach(service => {
            this.app.use(service, (0, http_proxy_middleware_1.createProxyMiddleware)({
                target: userApiUrl,
                changeOrigin: true,
                onError: (err, req, res) => {
                    this.logger.error(`Proxy Error on ${service}`, err);
                    res.status(502).json({ error: true, message: 'Bad Gateway' });
                }
            }));
        });
        // Proxy to Admin API
        const adminApiUrl = process.env.ADMIN_API_URL || 'http://64.227.181.90:3002';
        // Explicitly proxy admin services if accessed without /admin prefix
        const adminServices = [
            '/chargers', '/sites', '/roles', '/commands', '/sessions', '/tariffs', '/dashboard', '/users'
        ];
        adminServices.forEach(service => {
            this.app.use(service, (0, http_proxy_middleware_1.createProxyMiddleware)({
                target: adminApiUrl,
                changeOrigin: true,
                onError: (err, req, res) => {
                    this.logger.error(`Proxy Error on ${service}`, err);
                    res.status(502).json({ error: true, message: 'Bad Gateway' });
                }
            }));
        });
        // We map /admin/* to /* on the admin-api
        this.app.use('/admin', (0, http_proxy_middleware_1.createProxyMiddleware)({
            target: adminApiUrl,
            changeOrigin: true,
            pathRewrite: {
                '^/admin': '',
            },
            onError: (err, req, res) => {
                this.logger.error(`Proxy Error on /admin`, err);
                res.status(502).json({ error: true, message: 'Bad Gateway' });
            }
        }));
    }
    start() {
        this.app.listen(this.port, () => {
            this.logger.info(`API Gateway running on port ${this.port}`);
        });
    }
}
exports.App = App;
//# sourceMappingURL=app.js.map