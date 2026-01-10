"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("./app");
const shared_1 = require("@ev-platform-v1/shared");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const logger = new shared_1.Logger('API-Gateway');
const PORT = process.env.GATEWAY_PORT ? parseInt(process.env.GATEWAY_PORT) : 3000;
const app = new app_1.App(PORT);
app.start();
//# sourceMappingURL=index.js.map