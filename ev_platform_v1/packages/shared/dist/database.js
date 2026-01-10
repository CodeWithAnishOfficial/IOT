"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.Database = void 0;
const mongoose_1 = __importDefault(require("mongoose"));
const logger_1 = require("./logger");
class Database {
    static instance;
    connection = null;
    logger;
    constructor() {
        this.logger = new logger_1.Logger('Database');
    }
    static getInstance() {
        if (!Database.instance) {
            Database.instance = new Database();
        }
        return Database.instance;
    }
    async connect(uri) {
        if (this.connection) {
            return this.connection;
        }
        try {
            this.logger.info('Connecting to MongoDB...');
            const result = await mongoose_1.default.connect(uri);
            this.connection = result.connection;
            this.logger.info('Connected to MongoDB successfully');
            return this.connection;
        }
        catch (error) {
            this.logger.error('Error connecting to MongoDB', error);
            throw error;
        }
    }
    async disconnect() {
        if (this.connection) {
            await mongoose_1.default.disconnect();
            this.connection = null;
            this.logger.info('Disconnected from MongoDB');
        }
    }
    getConnection() {
        return this.connection;
    }
}
exports.Database = Database;
//# sourceMappingURL=database.js.map