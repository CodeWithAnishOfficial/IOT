"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmailService = void 0;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('EmailService');
class EmailService {
    static async sendOTP(email, otp) {
        // TODO: Integrate real email service (Nodemailer/SendGrid)
        logger.info(`[MOCK] Sending OTP ${otp} to ${email}`);
        return true;
    }
}
exports.EmailService = EmailService;
//# sourceMappingURL=email.service.js.map