import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { validate } from '../middlewares/validate.middleware';
import { generateOtpSchema, verifyOtpSchema, googleLoginSchema } from '../schemas/auth.schema';

const router = Router();

router.post('/generate-otp', validate(generateOtpSchema), AuthController.generateOTP);
router.post('/verify-otp', validate(verifyOtpSchema), AuthController.verifyOTP);
router.post('/google-login', validate(googleLoginSchema), AuthController.googleSignIn);

export default router;
