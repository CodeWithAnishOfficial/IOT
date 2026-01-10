"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const shared_1 = require("@ev-platform-v1/shared");
(0, shared_1.initTracing)('admin-api');
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const shared_2 = require("@ev-platform-v1/shared");
const dotenv_1 = __importDefault(require("dotenv"));
const charger_routes_1 = __importDefault(require("./routes/charger.routes"));
const remote_command_routes_1 = __importDefault(require("./routes/remote-command.routes"));
const user_routes_1 = __importDefault(require("./routes/user.routes"));
const tariff_routes_1 = __importDefault(require("./routes/tariff.routes"));
const dashboard_routes_1 = __importDefault(require("./routes/dashboard.routes"));
const support_routes_1 = __importDefault(require("./routes/support.routes"));
const session_routes_1 = __importDefault(require("./routes/session.routes"));
const site_routes_1 = __importDefault(require("./routes/site.routes"));
const role_routes_1 = __importDefault(require("./routes/role.routes"));
const auth_routes_1 = __importDefault(require("./routes/auth.routes"));
const seeder_service_1 = require("./services/seeder.service");
const prom_client_1 = __importDefault(require("prom-client"));
const path_1 = __importDefault(require("path"));
dotenv_1.default.config();
const logger = new shared_2.Logger('Admin-API');
const app = (0, express_1.default)();
const PORT = process.env.ADMIN_API_PORT ? parseInt(process.env.ADMIN_API_PORT) : 3002;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ev_platform';
// Prometheus Metrics
const collectDefaultMetrics = prom_client_1.default.collectDefaultMetrics;
collectDefaultMetrics({ register: prom_client_1.default.register });
app.use((0, cors_1.default)());
app.use(express_1.default.json());
app.use('/uploads', express_1.default.static(path_1.default.join(process.cwd(), 'uploads')));
// Routes
app.use('/chargers', charger_routes_1.default);
app.use('/sites', site_routes_1.default);
app.use('/roles', role_routes_1.default);
app.use('/commands', remote_command_routes_1.default);
app.use('/users', user_routes_1.default);
app.use('/tariffs', tariff_routes_1.default);
app.use('/dashboard', dashboard_routes_1.default);
app.use('/support', support_routes_1.default);
app.use('/sessions', session_routes_1.default);
app.use('/auth', auth_routes_1.default);
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prom_client_1.default.register.contentType);
    res.end(await prom_client_1.default.register.metrics());
});
app.get('/health', (req, res) => {
    res.json({ status: 'UP', service: 'Admin-API' });
});
const start = async () => {
    try {
        await shared_2.Database.getInstance().connect(MONGO_URI);
        // Seed initial data
        await seeder_service_1.SeederService.seed();
        app.listen(PORT, () => {
            logger.info(`Admin API running on port ${PORT}`);
        });
    }
    catch (error) {
        logger.error('Failed to start Admin API', error);
        process.exit(1);
    }
};
start();
//# sourceMappingURL=index.js.map