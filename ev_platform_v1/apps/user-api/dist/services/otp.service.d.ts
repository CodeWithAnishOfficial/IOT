export declare class OTPService {
    private static otpStore;
    static generateOTP(email: string): Promise<number>;
    static verifyOTP(email: string, otp: number): boolean;
}
