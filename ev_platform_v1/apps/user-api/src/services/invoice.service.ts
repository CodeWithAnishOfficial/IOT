import PDFDocument from 'pdfkit';
import nodemailer from 'nodemailer';
import { ChargingSession } from '@ev-platform-v1/shared';
import fs from 'fs';

export class InvoiceService {
  static async generateInvoice(session: any): Promise<Buffer> {
    return new Promise((resolve) => {
      const doc = new PDFDocument();
      const buffers: Buffer[] = [];

      doc.on('data', buffers.push.bind(buffers));
      doc.on('end', () => resolve(Buffer.concat(buffers)));

      doc.fontSize(25).text('EV Charging Invoice', { align: 'center' });
      doc.moveDown();
      doc.fontSize(12).text(`Session ID: ${session.session_id}`);
      doc.text(`Date: ${new Date(session.start_time).toLocaleDateString()}`);
      doc.text(`Total Energy: ${session.total_energy} kWh`);
      doc.text(`Total Cost: ₹${session.cost}`);
      doc.text(`Status: ${session.status}`);
      
      doc.end();
    });
  }

  static async sendInvoiceEmail(email: string, invoiceBuffer: Buffer, session: any) {
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp.ethereal.email',
      port: 587,
      auth: {
        user: process.env.SMTP_USER || 'test',
        pass: process.env.SMTP_PASS || 'test'
      }
    });

    await transporter.sendMail({
      from: '"EV Platform" <noreply@evplatform.com>',
      to: email,
      subject: `Invoice for Charging Session ${session.session_id}`,
      text: 'Please find attached your charging invoice.',
      attachments: [
        {
          filename: `invoice-${session.session_id}.pdf`,
          content: invoiceBuffer
        }
      ]
    });
  }
}
