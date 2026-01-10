"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisService = void 0;
const ioredis_1 = __importDefault(require("ioredis"));
const logger_1 = require("./logger");
class RedisService {
    static instance;
    pub;
    sub;
    logger;
    constructor() {
        this.logger = new logger_1.Logger('RedisService');
        const redisUrl = process.env.REDIS_URL || 'redis://64.227.181.90:6379';
        this.pub = new ioredis_1.default(redisUrl);
        this.sub = new ioredis_1.default(redisUrl);
    }
    static getInstance() {
        if (!RedisService.instance) {
            RedisService.instance = new RedisService();
        }
        return RedisService.instance;
    }
    async publish(channel, message) {
        try {
            await this.pub.publish(channel, JSON.stringify(message));
        }
        catch (error) {
            this.logger.error(`Error publishing to ${channel}`, error);
        }
    }
    async subscribe(channel, callback) {
        try {
            await this.sub.subscribe(channel);
            this.sub.on('message', (ch, msg) => {
                if (ch === channel) {
                    callback(JSON.parse(msg));
                }
            });
        }
        catch (error) {
            this.logger.error(`Error subscribing to ${channel}`, error);
        }
    }
    // Set remote command for OCPP server to pick up
    async sendCommand(chargerId, command, payload) {
        const channel = `ocpp:command:${chargerId}`;
        await this.publish('ocpp:commands', { chargerId, command, payload });
    }
    async set(key, value, ttlSeconds) {
        try {
            const stringValue = JSON.stringify(value);
            if (ttlSeconds) {
                await this.pub.set(key, stringValue, 'EX', ttlSeconds);
            }
            else {
                await this.pub.set(key, stringValue);
            }
        }
        catch (error) {
            this.logger.error(`Error setting key ${key}`, error);
        }
    }
    async get(key) {
        try {
            const value = await this.pub.get(key);
            if (value) {
                return JSON.parse(value);
            }
            return null;
        }
        catch (error) {
            this.logger.error(`Error getting key ${key}`, error);
            return null;
        }
    }
    async del(key) {
        try {
            await this.pub.del(key);
        }
        catch (error) {
            this.logger.error(`Error deleting key ${key}`, error);
        }
    }
}
exports.RedisService = RedisService;
//# sourceMappingURL=redis.service.js.map