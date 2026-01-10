"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const otp_service_1 = require("../services/otp.service");
const email_service_1 = require("../services/email.service");
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const google_auth_library_1 = require("google-auth-library");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const logger = new shared_1.Logger('AuthController');
const JWT_SECRET = process.env.JWT_SECRET || 'ev-platform-secret-key';
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;
const client = new google_auth_library_1.OAuth2Client(GOOGLE_CLIENT_ID);
class AuthController {
    static async generateOTP(req, res) {
        try {
            const { email_id } = req.body;
            if (!email_id)
                return res.status(400).json({ error: true, message: 'Email ID is required' });
            const otp = await otp_service_1.OTPService.generateOTP(email_id);
            await email_service_1.EmailService.sendOTP(email_id, otp);
            res.status(200).json({ error: false, message: `OTP sent to ${email_id}` });
        }
        catch (error) {
            logger.error('GenerateOTP error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async initiateRegistration(req, res) {
        try {
            const { email_id } = req.body;
            if (!email_id)
                return res.status(400).json({ error: true, message: 'Email ID is required' });
            const existingUser = await shared_1.User.findOne({ email_id });
            if (existingUser)
                return res.status(400).json({ error: true, message: 'User already exists. Please login.' });
            const otp = await otp_service_1.OTPService.generateOTP(email_id);
            await email_service_1.EmailService.sendOTP(email_id, otp);
            res.status(200).json({ error: false, message: `OTP sent to ${email_id} for registration` });
        }
        catch (error) {
            logger.error('InitiateRegistration error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async verifyOTP(req, res) {
        try {
            const { email_id, otp, username, phone_no, password } = req.body;
            if (!email_id || !otp)
                return res.status(400).json({ error: true, message: 'Email and OTP required' });
            const isValid = otp_service_1.OTPService.verifyOTP(email_id, parseInt(otp));
            if (!isValid)
                return res.status(400).json({ error: true, message: 'Invalid or expired OTP' });
            let user = await shared_1.User.findOne({ email_id });
            if (!user) {
                // Register new user
                const lastUser = await shared_1.User.findOne().sort({ user_id: -1 });
                const newUserId = lastUser ? lastUser.user_id + 1 : 1;
                const hashedPassword = password ? await bcryptjs_1.default.hash(password, 10) : undefined;
                user = await shared_1.User.create({
                    user_id: newUserId,
                    email_id,
                    username: username || undefined,
                    phone_no: phone_no || undefined,
                    password: hashedPassword,
                    role_id: 5, // User role
                    status: true
                });
            }
            const token = jsonwebtoken_1.default.sign({ email_id: user.email_id, user_id: user.user_id, role_id: user.role_id }, JWT_SECRET);
            res.status(200).json({
                error: false,
                message: 'Login successful',
                token,
                data: user
            });
        }
        catch (error) {
            logger.error('VerifyOTP error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async passwordLogin(req, res) {
        try {
            const { email_id, password } = req.body;
            if (!email_id || !password)
                return res.status(400).json({ error: true, message: 'Email and password required' });
            const user = await shared_1.User.findOne({ email_id });
            if (!user)
                return res.status(400).json({ error: true, message: 'User not found' });
            if (!user.password)
                return res.status(400).json({ error: true, message: 'Password not set. Please login via OTP or Google.' });
            const isMatch = await bcryptjs_1.default.compare(password, user.password);
            if (!isMatch)
                return res.status(400).json({ error: true, message: 'Invalid password' });
            const token = jsonwebtoken_1.default.sign({ email_id: user.email_id, user_id: user.user_id, role_id: user.role_id }, JWT_SECRET);
            res.status(200).json({
                error: false,
                message: 'Login successful',
                token,
                data: user
            });
        }
        catch (error) {
            logger.error('PasswordLogin error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async googleSignIn(req, res) {
        try {
            const { idToken } = req.body;
            if (!idToken)
                return res.status(400).json({ error: true, message: 'Google ID Token required' });
            const ticket = await client.verifyIdToken({
                idToken,
                audience: GOOGLE_CLIENT_ID,
            });
            const payload = ticket.getPayload();
            if (!payload || !payload.email)
                return res.status(400).json({ error: true, message: 'Invalid Google Token' });
            const { email, name, picture } = payload;
            let user = await shared_1.User.findOne({ email_id: email });
            if (!user) {
                const lastUser = await shared_1.User.findOne().sort({ user_id: -1 });
                const newUserId = lastUser ? lastUser.user_id + 1 : 1;
                user = await shared_1.User.create({
                    user_id: newUserId,
                    username: name,
                    email_id: email,
                    role_id: 5,
                    status: true
                });
            }
            const token = jsonwebtoken_1.default.sign({ email_id: user.email_id, user_id: user.user_id, role_id: user.role_id }, JWT_SECRET);
            res.status(200).json({
                error: false,
                message: 'Google Login successful',
                token,
                data: user
            });
        }
        catch (error) {
            logger.error('GoogleSignIn error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.AuthController = AuthController;
//# sourceMappingURL=auth.controller.js.map