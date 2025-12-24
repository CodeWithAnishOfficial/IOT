export class OTPService {
  private static otpStore: Map<string, { otp: number; expiresAt: number }> = new Map();

  static async generateOTP(email: string): Promise<number> {
    const otp = Math.floor(100000 + Math.random() * 900000);
    this.otpStore.set(email, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });
    return otp;
  }

  static verifyOTP(email: string, otp: number): boolean {
    const stored = this.otpStore.get(email);
    if (!stored) return false;
    if (Date.now() > stored.expiresAt) {
      this.otpStore.delete(email);
      return false;
    }
    if (stored.otp !== otp) return false;

    this.otpStore.delete(email);
    return true;
  }
}
