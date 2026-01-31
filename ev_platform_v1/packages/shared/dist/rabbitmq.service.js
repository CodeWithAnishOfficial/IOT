"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.RabbitMQService = void 0;
const amqp = __importStar(require("amqplib"));
const logger_1 = require("./logger");
class RabbitMQService {
    static instance;
    connection = null;
    channel = null;
    logger;
    url;
    constructor() {
        this.logger = new logger_1.Logger('RabbitMQService');
        this.url = process.env.RABBITMQ_URL || 'amqp://user:password@192.168.1.8:5672';
    }
    static getInstance() {
        if (!RabbitMQService.instance) {
            RabbitMQService.instance = new RabbitMQService();
        }
        return RabbitMQService.instance;
    }
    async connect(retries = 10, delay = 5000) {
        if (this.connection)
            return;
        while (retries > 0) {
            try {
                this.logger.info(`Connecting to RabbitMQ at ${this.url}`);
                this.connection = await amqp.connect(this.url);
                this.channel = await this.connection.createChannel();
                this.connection.on('error', (err) => {
                    this.logger.error('RabbitMQ connection error', err);
                    this.connection = null;
                    this.channel = null;
                });
                this.connection.on('close', () => {
                    this.logger.warn('RabbitMQ connection closed');
                    this.connection = null;
                    this.channel = null;
                });
                this.logger.info('Connected to RabbitMQ');
                return;
            }
            catch (error) {
                this.logger.error(`Failed to connect to RabbitMQ. Retries left: ${retries - 1}`, error);
                retries -= 1;
                if (retries === 0) {
                    throw error;
                }
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }
    async assertQueue(queue) {
        if (!this.channel)
            await this.connect();
        if (this.channel) {
            await this.channel.assertQueue(queue, { durable: true });
        }
    }
    async publish(queue, message) {
        try {
            if (!this.channel)
                await this.connect();
            if (!this.channel) {
                throw new Error('Channel not available');
            }
            await this.assertQueue(queue);
            const buffer = Buffer.from(JSON.stringify(message));
            return this.channel.sendToQueue(queue, buffer, { persistent: true });
        }
        catch (error) {
            this.logger.error(`Error publishing to queue ${queue}`, error);
            return false;
        }
    }
    async consume(queue, callback) {
        try {
            if (!this.channel)
                await this.connect();
            if (!this.channel) {
                throw new Error('Channel not available');
            }
            await this.assertQueue(queue);
            this.channel.consume(queue, async (msg) => {
                if (msg) {
                    try {
                        const content = JSON.parse(msg.content.toString());
                        await callback(content);
                        this.channel?.ack(msg);
                    }
                    catch (error) {
                        this.logger.error(`Error processing message from ${queue}`, error);
                        this.channel?.nack(msg, false, false);
                    }
                }
            });
        }
        catch (error) {
            this.logger.error(`Error consuming from ${queue}`, error);
        }
    }
}
exports.RabbitMQService = RabbitMQService;
//# sourceMappingURL=rabbitmq.service.js.map