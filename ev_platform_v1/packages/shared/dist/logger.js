"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
class Logger {
    serviceName;
    constructor(serviceName) {
        this.serviceName = serviceName;
    }
    info(message, meta) {
        console.log(JSON.stringify({ level: 'info', service: this.serviceName, message, meta, timestamp: new Date() }));
    }
    error(message, error) {
        console.error(JSON.stringify({ level: 'error', service: this.serviceName, message, error, timestamp: new Date() }));
    }
    warn(message, meta) {
        console.warn(JSON.stringify({ level: 'warn', service: this.serviceName, message, meta, timestamp: new Date() }));
    }
}
exports.Logger = Logger;
//# sourceMappingURL=logger.js.map