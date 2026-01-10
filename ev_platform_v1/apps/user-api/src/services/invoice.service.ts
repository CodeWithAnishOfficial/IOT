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

      // --- Header ---
      doc.font('Helvetica-Bold').fontSize(20).text('QUANTUM EV', 50, 50);
      doc.fontSize(10).text('123 Innovation Dr, Tech City', 50, 75);
      doc.text('Support: help@quantum-ev.com', 50, 90);

      doc.font('Helvetica-Bold').fontSize(24).text('INVOICE', 400, 50, { align: 'right' });
      doc.fontSize(10).text(`Invoice #: INV-${session.session_id}`, 400, 80, { align: 'right' });
      doc.text(`Date: ${new Date().toLocaleDateString()}`, 400, 95, { align: 'right' });

      doc.moveDown(2);
      
      // --- Bill To ---
      doc.rect(50, 130, 500, 1).fill('#CCCCCC'); // Divider
      doc.moveDown(2);
      
      doc.font('Helvetica-Bold').fontSize(12).fillColor('black').text('Bill To:', 50, 150);
      doc.font('Helvetica').fontSize(12).text(session.email_id || 'Valued Customer', 50, 170);

      // --- Session Details ---
      doc.font('Helvetica-Bold').text('Session Details:', 300, 150);
      doc.font('Helvetica').fontSize(10);
      doc.text(`Station ID: ${session.charger_id || 'Unknown'}`, 300, 170);
      doc.text(`Connector: ${session.connector_id || 1}`, 300, 185);
      doc.text(`Start Time: ${session.start_time ? new Date(session.start_time).toLocaleString() : '-'}`, 300, 200);
      doc.text(`End Time: ${session.stop_time ? new Date(session.stop_time).toLocaleString() : '-'}`, 300, 215);

      doc.moveDown(4);

      // --- Table Header ---
      const tableTop = 280;
      doc.rect(50, tableTop, 500, 30).fill('#EEEEEE');
      doc.fillColor('black');
      doc.font('Helvetica-Bold').fontSize(12);
      doc.text('Description', 60, tableTop + 10);
      doc.text('Quantity', 250, tableTop + 10);
      doc.text('Rate', 350, tableTop + 10);
      doc.text('Amount (INR)', 450, tableTop + 10, { width: 90, align: 'right' });

      // --- Table Rows ---
      let y = tableTop + 40;
      doc.font('Helvetica').fontSize(10);
      
      // Energy
      const energyKwh = (session.unit_consumed || 0) / 1000;
      const energyCost = parseFloat(session.price || '0');
      const rate = energyKwh > 0 ? (energyCost / energyKwh).toFixed(2) : '0';

      doc.text('Energy Charges', 60, y);
      doc.text(`${energyKwh.toFixed(2)} kWh`, 250, y);
      doc.text(`₹${rate}/kWh`, 350, y);
      doc.text(energyCost.toFixed(2), 450, y, { width: 90, align: 'right' });
      y += 20;

      // Service Fee
      if (session.service_fee && parseFloat(session.service_fee) > 0) {
        doc.text('Service Fee', 60, y);
        doc.text('1', 250, y);
        doc.text('-', 350, y);
        doc.text(parseFloat(session.service_fee).toFixed(2), 450, y, { width: 90, align: 'right' });
        y += 20;
      }

      // Parking Fee
      if (session.parking_fee && parseFloat(session.parking_fee) > 0) {
        doc.text('Parking Fee', 60, y);
        doc.text('-', 250, y);
        doc.text('-', 350, y);
        doc.text(parseFloat(session.parking_fee).toFixed(2), 450, y, { width: 90, align: 'right' });
        y += 20;
      }

      // GST
      if (session.gst_amount && parseFloat(session.gst_amount) > 0) {
        doc.text(`GST (${session.gst_percentage || 18}%)`, 60, y);
        doc.text('-', 250, y);
        doc.text('-', 350, y);
        doc.text(parseFloat(session.gst_amount).toFixed(2), 450, y, { width: 90, align: 'right' });
        y += 20;
      }

      // --- Total ---
      doc.moveDown();
      doc.rect(350, y + 10, 200, 1).fill('black'); // Line above total
      y += 20;
      
      doc.fillColor('black');
      doc.font('Helvetica-Bold').fontSize(14);
      doc.text('Total Amount', 300, y, { align: 'right' });
      doc.text(`₹${session.cost || '0.00'}`, 450, y, { width: 90, align: 'right' });

      // --- Footer ---
      doc.fontSize(10).font('Helvetica').text('Thank you for charging with Quantum EV!', 50, 700, { align: 'center' });
      
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
