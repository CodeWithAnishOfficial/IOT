import mongoose, { Schema, Document } from 'mongoose';

export interface IVehicle extends Document {
  user_id: string; // Email or User ID
  make: string;
  model: string;
  year: number;
  vin?: string;
  plate_no?: string;
  connector_type: 'Type2' | 'CCS2' | 'Chademo' | 'GB/T';
  is_default: boolean;
  created_at: Date;
}

const VehicleSchema: Schema = new Schema({
  user_id: { type: String, required: true },
  make: { type: String, required: true },
  model: { type: String, required: true },
  year: { type: Number, required: true },
  vin: { type: String },
  plate_no: { type: String },
  connector_type: { type: String, enum: ['Type2', 'CCS2', 'Chademo', 'GB/T'], required: true },
  is_default: { type: Boolean, default: false },
  created_at: { type: Date, default: Date.now }
});

export const Vehicle = mongoose.model<IVehicle>('Vehicle', VehicleSchema);
