"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || 'default_secret';
const authMiddleware = (req, res, next) => {
    let token = req.headers.authorization?.split(' ')[1];
    if (!token && req.query.token) {
        token = req.query.token;
    }
    if (!token) {
        return res.status(401).json({ error: true, message: 'Unauthorized' });
    }
    try {
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET, { ignoreExpiration: true });
        // @ts-ignore
        req.user = decoded;
        next();
    }
    catch (error) {
        console.error(`Auth Middleware Error: ${error.message}`);
        return res.status(401).json({ error: true, message: 'Invalid token' });
    }
};
exports.authMiddleware = authMiddleware;
//# sourceMappingURL=auth.middleware.js.map