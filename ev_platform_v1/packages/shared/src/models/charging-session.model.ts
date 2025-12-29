import mongoose, { Schema, Document } from 'mongoose';

export interface IChargingSession extends Document {
  session_id: string; // Internal UUID
  transaction_id?: number; // OCPP Transaction ID
  charger_id: string;
  connector_id: number;
  user_id: string; // Email or User ID
  start_time: Date;
  stop_time?: Date;
  meter_start: number;
  meter_stop?: number;
  total_energy: number; // In Wh or kWh
  cost: number;
  status: 'pending' | 'active' | 'stopping' | 'completed' | 'error' | 'failed' | 'stopped';
  auth_tag?: string;
}

const ChargingSessionSchema: Schema = new Schema({
  session_id: { type: String, required: true, unique: true },
  transaction_id: { type: Number },
  charger_id: { type: String, required: true },
  connector_id: { type: Number, required: true },
  user_id: { type: String, required: true },
  start_time: { type: Date, default: Date.now },
  stop_time: { type: Date },
  meter_start: { type: Number, default: 0 },
  meter_stop: { type: Number },
  total_energy: { type: Number, default: 0 },
  cost: { type: Number, default: 0 },
  status: { type: String, enum: ['pending', 'active', 'stopping', 'completed', 'error', 'failed', 'stopped'], default: 'pending' },
  auth_tag: { type: String }
});

export const ChargingSession = mongoose.model<IChargingSession>('ChargingSession', ChargingSessionSchema);
