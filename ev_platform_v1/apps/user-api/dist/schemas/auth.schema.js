"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.googleLoginSchema = exports.verifyOtpSchema = exports.generateOtpSchema = void 0;
const zod_1 = require("zod");
exports.generateOtpSchema = zod_1.z.object({
    body: zod_1.z.object({
        email_id: zod_1.z.string().email()
    })
});
exports.verifyOtpSchema = zod_1.z.object({
    body: zod_1.z.object({
        email_id: zod_1.z.string().email(),
        otp: zod_1.z.string().or(zod_1.z.number()),
        username: zod_1.z.string().optional(),
        phone_no: zod_1.z.string().optional()
    })
});
exports.googleLoginSchema = zod_1.z.object({
    body: zod_1.z.object({
        idToken: zod_1.z.string().min(1)
    })
});
//# sourceMappingURL=auth.schema.js.map