import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { validate } from '../middlewares/validate.middleware';
import { generateOtpSchema, verifyOtpSchema, googleLoginSchema } from '../schemas/auth.schema';

const router = Router();

// Route: POST /auth/register
// Description: Check if user exists and send OTP for registration
router.post('/register', validate(generateOtpSchema), AuthController.initiateRegistration);

// Route: POST /auth/generate-otp
// Description: Generate and send OTP for login
router.post('/generate-otp', validate(generateOtpSchema), AuthController.generateOTP);

// Route: POST /auth/verify-otp
// Description: Verify OTP and log in or register the user
router.post('/verify-otp', validate(verifyOtpSchema), AuthController.verifyOTP);

// Route: POST /auth/login
// Description: Login with email and password
router.post('/login', AuthController.passwordLogin);

// Route: POST /auth/google-login
// Description: Authenticate using Google ID Token
router.post('/google-login', validate(googleLoginSchema), AuthController.googleSignIn);

export default router;
