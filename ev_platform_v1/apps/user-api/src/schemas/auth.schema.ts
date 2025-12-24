import { z } from 'zod';

export const generateOtpSchema = z.object({
  body: z.object({
    email_id: z.string().email()
  })
});

export const verifyOtpSchema = z.object({
  body: z.object({
    email_id: z.string().email(),
    otp: z.string().or(z.number()) // OTP can be string or number in input
  })
});

export const googleLoginSchema = z.object({
  body: z.object({
    idToken: z.string().min(1)
  })
});
