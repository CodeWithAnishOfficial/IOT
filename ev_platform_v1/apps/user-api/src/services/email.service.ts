import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('EmailService');

export class EmailService {
  static async sendOTP(email: string, otp: number): Promise<boolean> {
    // TODO: Integrate real email service (Nodemailer/SendGrid)
    logger.info(`[MOCK] Sending OTP ${otp} to ${email}`);
    return true;
  }
}
