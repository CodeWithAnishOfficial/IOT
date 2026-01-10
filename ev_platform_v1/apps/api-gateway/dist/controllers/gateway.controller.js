"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GatewayController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const prom_client_1 = __importDefault(require("prom-client"));
const logger = new shared_1.Logger('GatewayController');
class GatewayController {
    static healthCheck(req, res) {
        res.status(200).json({ status: 'UP', service: 'API-Gateway' });
    }
    static async getMetrics(req, res) {
        res.set('Content-Type', prom_client_1.default.register.contentType);
        res.end(await prom_client_1.default.register.metrics());
    }
}
exports.GatewayController = GatewayController;
//# sourceMappingURL=gateway.controller.js.map