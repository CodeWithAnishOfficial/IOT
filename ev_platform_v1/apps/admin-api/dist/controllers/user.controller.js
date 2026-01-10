"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminUserController = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const logger = new shared_1.Logger('AdminUserController');
class AdminUserController {
    static async getAllUsers(req, res) {
        try {
            const page = parseInt(req.query.page) || 1;
            const limit = parseInt(req.query.limit) || 10;
            const skip = (page - 1) * limit;
            const users = await shared_1.User.find()
                .select('-password') // Assuming password field exists or we just exclude sensitive info
                .sort({ created_at: -1 })
                .skip(skip)
                .limit(limit);
            const total = await shared_1.User.countDocuments();
            res.json({
                error: false,
                data: users,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            });
        }
        catch (error) {
            logger.error('Error fetching users', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async getUserDetails(req, res) {
        try {
            const { id } = req.params;
            const user = await shared_1.User.findOne({ user_id: parseInt(id) });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            res.json({ error: false, data: user });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async toggleBlockUser(req, res) {
        try {
            const { id } = req.params;
            const { status } = req.body; // true = active, false = blocked
            const user = await shared_1.User.findOneAndUpdate({ user_id: parseInt(id) }, { status: status }, { new: true });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            res.json({ error: false, message: `User ${status ? 'unblocked' : 'blocked'}`, data: user });
        }
        catch (error) {
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async createUser(req, res) {
        try {
            const { email_id, username, phone_no, role_id, rfid_tag, status, password, wallet_bal } = req.body;
            if (!email_id)
                return res.status(400).json({ error: true, message: 'Email ID is required' });
            const existingUser = await shared_1.User.findOne({ email_id });
            if (existingUser)
                return res.status(400).json({ error: true, message: 'User with this email already exists' });
            const lastUser = await shared_1.User.findOne().sort({ user_id: -1 });
            const newUserId = lastUser ? lastUser.user_id + 1 : 1;
            const hashedPassword = password ? await bcryptjs_1.default.hash(password, 10) : undefined;
            const user = await shared_1.User.create({
                user_id: newUserId,
                email_id,
                username,
                phone_no,
                password: hashedPassword,
                role_id: role_id || 5, // Default to User
                rfid_tag: rfid_tag || undefined,
                status: status !== undefined ? status : true,
                wallet_bal: wallet_bal || 0
            });
            res.status(201).json({ error: false, message: 'User created successfully', data: user });
        }
        catch (error) {
            logger.error('CreateUser error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async updateUser(req, res) {
        try {
            const { id } = req.params;
            const { email_id, username, phone_no, role_id, rfid_tag, status, wallet_bal, password } = req.body;
            // Build update object
            const updateData = { updated_at: new Date() };
            if (email_id)
                updateData.email_id = email_id;
            if (username)
                updateData.username = username;
            if (phone_no)
                updateData.phone_no = phone_no;
            if (role_id)
                updateData.role_id = role_id;
            if (rfid_tag)
                updateData.rfid_tag = rfid_tag;
            if (status !== undefined)
                updateData.status = status;
            if (wallet_bal !== undefined)
                updateData.wallet_bal = wallet_bal;
            if (password)
                updateData.password = await bcryptjs_1.default.hash(password, 10);
            const user = await shared_1.User.findOneAndUpdate({ user_id: parseInt(id) }, { $set: updateData }, { new: true });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            res.json({ error: false, message: 'User updated successfully', data: user });
        }
        catch (error) {
            logger.error('UpdateUser error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
    static async deleteUser(req, res) {
        try {
            const { id } = req.params;
            const user = await shared_1.User.findOneAndDelete({ user_id: parseInt(id) });
            if (!user)
                return res.status(404).json({ error: true, message: 'User not found' });
            res.json({ error: false, message: 'User deleted successfully' });
        }
        catch (error) {
            logger.error('DeleteUser error', error);
            res.status(500).json({ error: true, message: error.message });
        }
    }
}
exports.AdminUserController = AdminUserController;
//# sourceMappingURL=user.controller.js.map