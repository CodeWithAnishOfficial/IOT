import mongoose, { Schema, Document } from 'mongoose';

export interface IPayment extends Document {
  payment_id: number;
  user_id: number | string;
  username: string;
  phone_number: number | string;
  email_id: string;
  recharge_amount: number;
  transaction_id: string; // Razorpay Payment ID usually
  response: string; // "SUCCESS"
  recharged_date: Date;
  recharged_by: string;
  payment_method: string; // "UPI", "Card"
  status: boolean; // true for success?
}

const PaymentSchema: Schema = new Schema({
  payment_id: { type: Number, required: true, unique: true },
  user_id: { type: Schema.Types.Mixed, required: true },
  username: { type: String },
  phone_number: { type: Schema.Types.Mixed },
  email_id: { type: String, required: true },
  recharge_amount: { type: Number, required: true },
  transaction_id: { type: String, required: true },
  response: { type: String, default: 'SUCCESS' },
  recharged_date: { type: Date, default: Date.now },
  recharged_by: { type: String },
  payment_method: { type: String, default: 'UPI' },
  status: { type: Boolean, default: true }
});

export const Payment = mongoose.model<IPayment>('Payment', PaymentSchema);
