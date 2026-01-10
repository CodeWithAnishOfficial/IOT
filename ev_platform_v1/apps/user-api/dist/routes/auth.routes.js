"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("../controllers/auth.controller");
const validate_middleware_1 = require("../middlewares/validate.middleware");
const auth_schema_1 = require("../schemas/auth.schema");
const router = (0, express_1.Router)();
// Route: POST /auth/register
// Description: Check if user exists and send OTP for registration
router.post('/register', (0, validate_middleware_1.validate)(auth_schema_1.generateOtpSchema), auth_controller_1.AuthController.initiateRegistration);
// Route: POST /auth/generate-otp
// Description: Generate and send OTP for login
router.post('/generate-otp', (0, validate_middleware_1.validate)(auth_schema_1.generateOtpSchema), auth_controller_1.AuthController.generateOTP);
// Route: POST /auth/verify-otp
// Description: Verify OTP and log in or register the user
router.post('/verify-otp', (0, validate_middleware_1.validate)(auth_schema_1.verifyOtpSchema), auth_controller_1.AuthController.verifyOTP);
// Route: POST /auth/login
// Description: Login with email and password
router.post('/login', auth_controller_1.AuthController.passwordLogin);
// Route: POST /auth/google-login
// Description: Authenticate using Google ID Token
router.post('/google-login', (0, validate_middleware_1.validate)(auth_schema_1.googleLoginSchema), auth_controller_1.AuthController.googleSignIn);
exports.default = router;
//# sourceMappingURL=auth.routes.js.map