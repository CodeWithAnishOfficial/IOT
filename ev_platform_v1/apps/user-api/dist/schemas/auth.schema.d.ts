import { z } from 'zod';
export declare const generateOtpSchema: z.ZodObject<{
    body: z.ZodObject<{
        email_id: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        email_id: string;
    }, {
        email_id: string;
    }>;
}, "strip", z.ZodTypeAny, {
    body: {
        email_id: string;
    };
}, {
    body: {
        email_id: string;
    };
}>;
export declare const verifyOtpSchema: z.ZodObject<{
    body: z.ZodObject<{
        email_id: z.ZodString;
        otp: z.ZodUnion<[z.ZodString, z.ZodNumber]>;
        username: z.ZodOptional<z.ZodString>;
        phone_no: z.ZodOptional<z.ZodString>;
    }, "strip", z.ZodTypeAny, {
        email_id: string;
        otp: string | number;
        username?: string | undefined;
        phone_no?: string | undefined;
    }, {
        email_id: string;
        otp: string | number;
        username?: string | undefined;
        phone_no?: string | undefined;
    }>;
}, "strip", z.ZodTypeAny, {
    body: {
        email_id: string;
        otp: string | number;
        username?: string | undefined;
        phone_no?: string | undefined;
    };
}, {
    body: {
        email_id: string;
        otp: string | number;
        username?: string | undefined;
        phone_no?: string | undefined;
    };
}>;
export declare const googleLoginSchema: z.ZodObject<{
    body: z.ZodObject<{
        idToken: z.ZodString;
    }, "strip", z.ZodTypeAny, {
        idToken: string;
    }, {
        idToken: string;
    }>;
}, "strip", z.ZodTypeAny, {
    body: {
        idToken: string;
    };
}, {
    body: {
        idToken: string;
    };
}>;
