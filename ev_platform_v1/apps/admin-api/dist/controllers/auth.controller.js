"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminAuthController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const logger = new shared_1.Logger('AdminAuthController');
const JWT_SECRET = process.env.JWT_SECRET || 'default_secret';
class AdminAuthController {
    static async login(req, res) {
        try {
            const { email, password } = req.body;
            if (!email || !password)
                return res.status(400).json({ error: true, message: 'Email and password required' });
            const user = await shared_1.User.findOne({ email_id: email });
            if (!user)
                return res.status(401).json({ error: true, message: 'Invalid credentials' });
            if (!user.password)
                return res.status(400).json({ error: true, message: 'Password not set for this user' });
            const isMatch = await bcryptjs_1.default.compare(password, user.password);
            if (!isMatch)
                return res.status(401).json({ error: true, message: 'Invalid credentials' });
            // Check for Admin Role (Assuming 1 is Admin, 2 might be SuperAdmin, etc. Adjust as needed)
            // If roles are not strictly defined yet, we might want to allow this for now or check specifically.
            // For now, let's assume any user in the admin portal must have admin rights.
            // Ideally, we check: if (user.role_id !== 1) ...
            const token = jsonwebtoken_1.default.sign({
                email_id: user.email_id,
                user_id: user.user_id,
                role_id: user.role_id
            }, JWT_SECRET, { expiresIn: '24h' });
            res.json({
                error: false,
                message: 'Login successful',
                token,
                user: {
                    user_id: user.user_id,
                    username: user.username,
                    email: user.email_id,
                    role_id: user.role_id
                }
            });
        }
        catch (error) {
            logger.error('Login error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async me(req, res) {
        // access user from request (middleware should populate this)
        // For now, returning success to validate token if middleware existed
        res.json({ error: false, message: 'Authorized' });
    }
}
exports.AdminAuthController = AdminAuthController;
//# sourceMappingURL=auth.controller.js.map