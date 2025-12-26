import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  user_id: number;
  username?: string;
  email_id: string;
  password?: string;
  phone_no?: string;
  role_id: number;
  wallet_bal: number;
  rfid_tag?: string; // Physical card ID
  status: boolean;
  created_at: Date;
  updated_at: Date;
}

const UserSchema: Schema = new Schema({
  user_id: { type: Number, required: true, unique: true },
  username: { type: String },
  email_id: { type: String, required: true, unique: true },
  password: { type: String },
  phone_no: { type: String },
  role_id: { type: Number, required: true, default: 5 }, // Default to User role
  wallet_bal: { type: Number, default: 0 },
  rfid_tag: { type: String, unique: true, sparse: true },
  status: { type: Boolean, default: true },
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now }
});

export const User = mongoose.model<IUser>('User', UserSchema);
