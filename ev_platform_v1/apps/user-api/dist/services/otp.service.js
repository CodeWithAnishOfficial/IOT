"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.OTPService = void 0;
class OTPService {
    static otpStore = new Map();
    static async generateOTP(email) {
        const otp = Math.floor(100000 + Math.random() * 900000);
        this.otpStore.set(email, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });
        return otp;
    }
    static verifyOTP(email, otp) {
        const stored = this.otpStore.get(email);
        if (!stored)
            return false;
        if (Date.now() > stored.expiresAt) {
            this.otpStore.delete(email);
            return false;
        }
        if (stored.otp !== otp)
            return false;
        this.otpStore.delete(email);
        return true;
    }
}
exports.OTPService = OTPService;
//# sourceMappingURL=otp.service.js.map