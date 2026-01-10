import mongoose, { Document } from 'mongoose';
export interface IReservation extends Document {
    reservation_id: number;
    charger_id: string;
    connector_id: number;
    user_id: number;
    expiry_date: Date;
    status: 'Pending' | 'Accepted' | 'Rejected' | 'Cancelled' | 'Expired' | 'Used';
    created_at: Date;
}
export declare const Reservation: mongoose.Model<IReservation, {}, {}, {}, mongoose.Document<unknown, {}, IReservation, {}, mongoose.DefaultSchemaOptions> & IReservation & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IReservation>;
