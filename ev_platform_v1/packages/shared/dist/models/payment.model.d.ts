import mongoose, { Document } from 'mongoose';
export interface IPayment extends Document {
    payment_id: number;
    user_id: number | string;
    username: string;
    phone_number: number | string;
    email_id: string;
    recharge_amount: number;
    transaction_id: string;
    response: string;
    recharged_date: Date;
    recharged_by: string;
    payment_method: string;
    status: boolean;
}
export declare const Payment: mongoose.Model<IPayment, {}, {}, {}, mongoose.Document<unknown, {}, IPayment, {}, mongoose.DefaultSchemaOptions> & IPayment & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IPayment>;
