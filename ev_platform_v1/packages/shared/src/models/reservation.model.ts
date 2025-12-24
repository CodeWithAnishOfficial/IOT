import mongoose, { Schema, Document } from 'mongoose';

export interface IReservation extends Document {
  reservation_id: number;
  charger_id: string;
  connector_id: number;
  user_id: string; // Email or tag
  expiry_date: Date;
  status: 'Pending' | 'Accepted' | 'Rejected' | 'Cancelled' | 'Expired' | 'Used';
  created_at: Date;
}

const ReservationSchema: Schema = new Schema({
  reservation_id: { type: Number, required: true, unique: true },
  charger_id: { type: String, required: true },
  connector_id: { type: Number, required: true },
  user_id: { type: String, required: true },
  expiry_date: { type: Date, required: true },
  status: { type: String, enum: ['Pending', 'Accepted', 'Rejected', 'Cancelled', 'Expired', 'Used'], default: 'Pending' },
  created_at: { type: Date, default: Date.now }
});

export const Reservation = mongoose.model<IReservation>('Reservation', ReservationSchema);
