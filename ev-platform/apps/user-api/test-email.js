const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_PORT === '465',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD,
  },
});

async function main() {
  try {
    console.log('Testing SMTP connection...');
    console.log('Host:', process.env.SMTP_HOST);
    console.log('Port:', process.env.SMTP_PORT);
    console.log('User:', process.env.SMTP_USER);
    
    await transporter.verify();
    console.log('SMTP Connection successful!');
    
    const info = await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to: 'anishkumarak8686@gmail.com',
      subject: 'Test Email',
      text: 'This is a test email.',
    });
    
    console.log('Message sent: %s', info.messageId);
  } catch (error) {
    console.error('Error occurred:', error);
  }
}

main();
