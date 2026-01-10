import mongoose, { Document } from 'mongoose';
export interface IUser extends Document {
    user_id: number;
    username?: string;
    email_id: string;
    password?: string;
    phone_no?: string;
    role_id: number;
    wallet_bal: number;
    rfid_tag?: string;
    status: boolean;
    created_at: Date;
    updated_at: Date;
}
export declare const User: mongoose.Model<IUser, {}, {}, {}, mongoose.Document<unknown, {}, IUser, {}, mongoose.DefaultSchemaOptions> & IUser & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IUser>;
