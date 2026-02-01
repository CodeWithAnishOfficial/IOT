"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OCPPServer = void 0;
const ws_1 = require("ws");
const shared_1 = require("@ev-platform-v1/shared");
const connection_manager_1 = require("./core/connection.manager");
const message_router_1 = require("./core/message.router");
const https_1 = require("https");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const prom_client_1 = __importDefault(require("prom-client"));
class OCPPServer {
    port;
    wss = null;
    logger;
    connectionManager;
    redis;
    httpServer = null;
    constructor(port) {
        this.port = port;
        this.logger = new shared_1.Logger('OCPP-Server');
        this.connectionManager = new connection_manager_1.ConnectionManager();
        this.redis = shared_1.RedisService.getInstance();
        // Prometheus
        const collectDefaultMetrics = prom_client_1.default.collectDefaultMetrics;
        collectDefaultMetrics({ register: prom_client_1.default.register });
        this.initializeRedisListeners();
    }
    initializeRedisListeners() {
        this.redis.subscribe('ocpp:commands', async (data) => {
            const { chargerId, command, payload } = data;
            this.logger.info(`Received remote command ${command} for ${chargerId}`);
            const connection = this.connectionManager.getConnection(chargerId);
            if (connection && connection.isAlive) {
                // Send command to charger (OCPP Type 2 Request)
                const requestId = Date.now().toString();
                // [2, UniqueId, Action, Payload]
                connection.send([2, requestId, command, payload]);
                // SELF-HEALING: If we can send a command, the charger is ONLINE.
                // Ensure DB reflects this to prevent 'Station is offline' errors in User-API.
                shared_1.Charger.updateOne({ charger_id: chargerId }, { $set: { status: 'online' } }).catch(err => {
                    this.logger.error(`Failed to update status to online for ${chargerId}`, err);
                });
            }
            else {
                this.logger.warn(`Charger ${chargerId} not connected or offline. Cannot send ${command}`);
                try {
                    await shared_1.Charger.updateOne({ charger_id: chargerId }, { $set: { status: 'offline' } });
                    this.logger.info(`Updated status to offline for ${chargerId}`);
                }
                catch (err) {
                    this.logger.error(`Failed to update status for ${chargerId}`, err);
                }
            }
        });
    }
    async start() {
        return new Promise((resolve) => {
            // Basic TLS Security Profile (Profile 2 or 3)
            // Check for certificates
            const certPath = process.env.TLS_CERT_PATH || path_1.default.join(__dirname, '../certs/server.cert');
            const keyPath = process.env.TLS_KEY_PATH || path_1.default.join(__dirname, '../certs/server.key');
            const caPath = process.env.TLS_CA_PATH || path_1.default.join(__dirname, '../certs/ca.cert');
            let serverOptions = {};
            if (fs_1.default.existsSync(certPath) && fs_1.default.existsSync(keyPath)) {
                this.logger.info('Starting with TLS support (Security Profile 2/3)');
                serverOptions = {
                    cert: fs_1.default.readFileSync(certPath),
                    key: fs_1.default.readFileSync(keyPath),
                    // For Profile 3 (Mutual TLS), we need to request client cert and verify against CA
                    requestCert: process.env.OCPP_SECURITY_PROFILE === '3',
                    rejectUnauthorized: process.env.OCPP_SECURITY_PROFILE === '3',
                };
                if (process.env.OCPP_SECURITY_PROFILE === '3' && fs_1.default.existsSync(caPath)) {
                    serverOptions.ca = [fs_1.default.readFileSync(caPath)];
                }
                this.httpServer = (0, https_1.createServer)(serverOptions);
                // Add Metrics endpoint to HTTPS server
                this.httpServer.on('request', async (req, res) => {
                    if (req.url === '/metrics' && req.method === 'GET') {
                        res.setHeader('Content-Type', prom_client_1.default.register.contentType);
                        res.end(await prom_client_1.default.register.metrics());
                        return;
                    }
                    if (req.url === '/health' && req.method === 'GET') {
                        res.setHeader('Content-Type', 'application/json');
                        res.end(JSON.stringify({ status: 'UP', service: 'OCPP-Server' }));
                        return;
                    }
                });
                this.wss = new ws_1.WebSocketServer({ server: this.httpServer });
            }
            else {
                this.logger.warn('Certificates not found. Starting in insecure mode (ws://).');
                this.wss = new ws_1.WebSocketServer({ port: this.port });
                // NOTE: In WS mode (no http server passed), ws creates one internally but we can't easily attach routes to it unless we create our own http server.
                // For simplicity, let's assume secure mode or we accept no metrics in insecure mode for now, or create a separate http server for metrics.
            }
            if (this.wss) {
                this.wss.on('connection', (ws, req) => {
                    // Verify Client Certificate if Profile 3
                    if (process.env.OCPP_SECURITY_PROFILE === '3') {
                        const socket = req.socket;
                        if (socket.authorized) {
                            const cert = socket.getPeerCertificate();
                            this.logger.info(`Client authorized: ${cert.subject.CN}`);
                        }
                        else {
                            this.logger.error(`Client unauthorized: ${socket.authorizationError}`);
                            ws.close();
                            return;
                        }
                    }
                    // Handle Async Connection
                    // We must handle messages immediately to avoid missing them while async auth happens
                    const messageQueue = [];
                    let authenticatedConnection = null;
                    let isAuthenticating = true;
                    ws.on('message', (message) => {
                        if (isAuthenticating) {
                            messageQueue.push(message);
                        }
                        else if (authenticatedConnection) {
                            this.processMessage(authenticatedConnection, message);
                        }
                    });
                    this.connectionManager.handleConnection(ws, req).then(connection => {
                        isAuthenticating = false;
                        if (connection) {
                            authenticatedConnection = connection;
                            // Process queued messages
                            while (messageQueue.length > 0) {
                                const msg = messageQueue.shift();
                                if (msg)
                                    this.processMessage(connection, msg);
                            }
                        }
                        else {
                            // Connection rejected
                            ws.close();
                        }
                    }).catch(err => {
                        this.logger.error('Error handling connection', err);
                        ws.close();
                    });
                });
                if (this.httpServer) {
                    this.httpServer.listen(this.port, () => {
                        this.logger.info(`OCPP Server (WSS) started on port ${this.port}`);
                        resolve();
                    });
                }
                else {
                    this.wss.on('listening', () => {
                        this.logger.info(`OCPP Server (WS) started on port ${this.port}`);
                        resolve();
                    });
                }
            }
        });
    }
    processMessage(connection, message) {
        try {
            const msgString = message.toString();
            // Keep connection alive on any activity
            if (connection) {
                connection.isAlive = true;
                connection.lastHeartbeat = new Date();
            }
            try {
                const parsed = JSON.parse(msgString);
                this.logger.info(`[${connection.id}] >>`, parsed);
                message_router_1.MessageRouter.handleMessage(connection, parsed);
            }
            catch (err) {
                this.logger.info(`[${connection.id}] >> ${msgString}`);
                throw err;
            }
        }
        catch (error) {
            this.logger.error('Error parsing message', error);
            // We might want to send a ProtocolError (CallError) if parsing fails, but we don't have a requestId
        }
    }
    stop() {
        if (this.wss) {
            this.wss.close(() => {
                this.logger.info('OCPP Server stopped');
            });
        }
        if (this.httpServer) {
            this.httpServer.close();
        }
    }
}
exports.OCPPServer = OCPPServer;
//# sourceMappingURL=server.js.map