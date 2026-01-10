import mongoose, { Document } from 'mongoose';
export interface IWalletTransaction extends Document {
    transaction_id: string;
    user_id: string;
    amount: number;
    type: 'credit' | 'debit';
    source: 'razorpay' | 'refund' | 'charging_session';
    reference_id?: string;
    status: 'success' | 'failed' | 'pending';
    created_at: Date;
}
export declare const WalletTransaction: mongoose.Model<IWalletTransaction, {}, {}, {}, mongoose.Document<unknown, {}, IWalletTransaction, {}, mongoose.DefaultSchemaOptions> & IWalletTransaction & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IWalletTransaction>;
