import mongoose, { Schema, Document } from 'mongoose';

export interface ITariff extends Document {
  name: string;
  type: 'FLAT' | 'TOU'; // Flat rate or Time-Of-Use
  currency: string;
  price_per_kwh: number; // Base price
  idle_fee_per_min?: number;
  peak_multiplier?: number;
  peak_hours?: Array<{
    start_time: string; // "18:00"
    end_time: string;   // "21:00"
  }>;
  created_at: Date;
  updated_at: Date;
}

const TariffSchema: Schema = new Schema({
  name: { type: String, required: true },
  type: { type: String, enum: ['FLAT', 'TOU'], default: 'FLAT' },
  currency: { type: String, default: 'INR' },
  price_per_kwh: { type: Number, required: true },
  idle_fee_per_min: { type: Number, default: 0 },
  peak_multiplier: { type: Number, default: 1.0 },
  peak_hours: [{
    start_time: String,
    end_time: String
  }],
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now }
});

export const Tariff = mongoose.model<ITariff>('Tariff', TariffSchema);
