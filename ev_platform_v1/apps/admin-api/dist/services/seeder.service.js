"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SeederService = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const logger = new shared_1.Logger('SeederService');
class SeederService {
    static async seed() {
        try {
            await this.seedRoles();
            await this.seedSuperAdmin();
        }
        catch (error) {
            logger.error('Seeding failed', error);
        }
    }
    static async seedRoles() {
        const roles = [
            { role_id: 1, role_name: 'Super Admin', description: 'Full access to all resources' },
            { role_id: 2, role_name: 'Admin', description: 'Administrative access' },
            { role_id: 3, role_name: 'Station Manager', description: 'Manage charging stations and sites' },
            { role_id: 4, role_name: 'Support', description: 'Customer support access' },
            { role_id: 5, role_name: 'User', description: 'Regular app user' }
        ];
        for (const role of roles) {
            const existingRole = await shared_1.Role.findOne({ role_id: role.role_id });
            if (!existingRole) {
                await shared_1.Role.create(role);
                logger.info(`Seeded Role: ${role.role_name}`);
            }
        }
    }
    static async seedSuperAdmin() {
        const superAdminEmail = 'superadmin@quantuminfosecurity.in';
        const existingUser = await shared_1.User.findOne({ email_id: superAdminEmail });
        if (!existingUser) {
            const lastUser = await shared_1.User.findOne().sort({ user_id: -1 });
            const newUserId = lastUser ? lastUser.user_id + 1 : 1;
            const hashedPassword = await bcryptjs_1.default.hash('admin123', 10);
            await shared_1.User.create({
                user_id: newUserId,
                username: 'Super Admin',
                email_id: superAdminEmail,
                phone_no: '+0000000000',
                password: hashedPassword,
                role_id: 1, // Super Admin
                status: true,
                wallet_bal: 1000 // Initial balance for testing
            });
            logger.info(`Seeded Super Admin: ${superAdminEmail}`);
        }
    }
}
exports.SeederService = SeederService;
//# sourceMappingURL=seeder.service.js.map