"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SseService = void 0;
const uuid_1 = require("uuid");
const ws_1 = __importDefault(require("ws"));
class SseService {
    static clients = [];
    static addSseClient(res, userId) {
        const clientId = (0, uuid_1.v4)();
        const newClient = { type: 'sse', id: clientId, res, userId };
        this.clients.push(newClient);
        res.on('close', () => {
            this.clients = this.clients.filter(c => c.id !== clientId);
        });
        return clientId;
    }
    static addWsClient(ws, userId) {
        const clientId = (0, uuid_1.v4)();
        const newClient = { type: 'ws', id: clientId, ws, userId };
        this.clients.push(newClient);
        ws.on('close', () => {
            this.clients = this.clients.filter(c => c.id !== clientId);
        });
        return clientId;
    }
    static sendToUser(userId, event, data) {
        const userClients = this.clients.filter(c => c.userId === userId);
        userClients.forEach(client => {
            if (client.type === 'sse') {
                client.res.write(`event: ${event}\n`);
                client.res.write(`data: ${JSON.stringify(data)}\n\n`);
            }
            else {
                if (client.ws.readyState === ws_1.default.OPEN) {
                    client.ws.send(JSON.stringify({ event, data }));
                }
            }
        });
    }
    static broadcast(event, data) {
        this.clients.forEach(client => {
            if (client.type === 'sse') {
                client.res.write(`event: ${event}\n`);
                client.res.write(`data: ${JSON.stringify(data)}\n\n`);
            }
            else {
                if (client.ws.readyState === ws_1.default.OPEN) {
                    client.ws.send(JSON.stringify({ event, data }));
                }
            }
        });
    }
    static startHeartbeat(intervalMs = 30000) {
        setInterval(() => {
            this.clients.forEach(client => {
                if (client.type === 'ws') {
                    if (client.ws.readyState === ws_1.default.OPEN) {
                        client.ws.send(JSON.stringify({ event: 'ping', data: {} }));
                    }
                }
            });
        }, intervalMs);
    }
    // Backward compatibility
    static addClient(res, userId) {
        return this.addSseClient(res, userId);
    }
}
exports.SseService = SseService;
//# sourceMappingURL=sse.service.js.map