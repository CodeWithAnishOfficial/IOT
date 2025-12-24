import mongoose, { Schema, Document } from 'mongoose';

export interface IWalletTransaction extends Document {
  transaction_id: string;
  user_id: string;
  amount: number;
  type: 'credit' | 'debit';
  source: 'razorpay' | 'refund' | 'charging_session';
  reference_id?: string; // Razorpay Payment ID or Session ID
  status: 'success' | 'failed' | 'pending';
  created_at: Date;
}

const WalletTransactionSchema: Schema = new Schema({
  transaction_id: { type: String, required: true, unique: true },
  user_id: { type: String, required: true },
  amount: { type: Number, required: true },
  type: { type: String, enum: ['credit', 'debit'], required: true },
  source: { type: String, enum: ['razorpay', 'refund', 'charging_session'], required: true },
  reference_id: { type: String },
  status: { type: String, enum: ['success', 'failed', 'pending'], default: 'pending' },
  created_at: { type: Date, default: Date.now }
});

export const WalletTransaction = mongoose.model<IWalletTransaction>('WalletTransaction', WalletTransactionSchema);
