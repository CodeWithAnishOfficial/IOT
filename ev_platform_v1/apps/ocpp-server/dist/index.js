"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const shared_1 = require("@ev-platform-v1/shared");
(0, shared_1.initTracing)('ocpp-server');
const server_1 = require("./server");
const shared_2 = require("@ev-platform-v1/shared");
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
// Load .env explicitly from one level up (since we are in src/)
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, '../.env') });
const logger = new shared_2.Logger('OCPP-Server');
logger.info(`Environment loaded. HEARTBEAT_INTERVAL=${process.env.HEARTBEAT_INTERVAL || 'undefined'}`);
const PORT = process.env.OCPP_PORT ? parseInt(process.env.OCPP_PORT) : 9220;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://192.168.0.25:27017/ev_platform';
const server = new server_1.OCPPServer(PORT);
const start = async () => {
    try {
        await shared_2.Database.getInstance().connect(MONGO_URI);
        // Connect to RabbitMQ
        const rabbit = shared_2.RabbitMQService.getInstance();
        await rabbit.connect();
        await server.start();
    }
    catch (err) {
        logger.error('Failed to start OCPP Server', err);
        process.exit(1);
    }
};
start();
process.on('SIGTERM', () => {
    logger.info('SIGTERM received. Shutting down...');
    server.stop();
});
//# sourceMappingURL=index.js.map