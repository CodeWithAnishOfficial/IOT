import mongoose, { Schema, Document } from 'mongoose';

export interface IChargingSession extends Document {
  charger_id: string;
  connector_id: number;
  connector_type?: number;
  session_id: number; // Changed to Number as per requirement
  transaction_id?: number;
  
  start_time: Date;
  stop_time?: Date;
  
  start_meter_value: number; // meter_start renamed/mapped
  current_meter_value?: number; // For live updates
  meter_stop?: number; // Kept for internal logic, or mapped to current_meter_value
  
  unit_consumed: number; // total_energy
  price: number;
  unit_price: number;
  
  error_code: string;
  vendor_error_code: string;
  
  location?: string;
  user_id: string | number; // Example shows 7 (number), existing was string
  email_id?: string;
  
  created_date: Date;
  modified_date: Date;
  
  status: boolean; // Example shows boolean true
  charger_status: string; // e.g. "Charging", "Completed"
  
  amount_to_charge?: number;
  consumed_amount: number;
  remaining_amount?: number;
  
  // Fees
  EB_fee?: string;
  association_commission?: string;
  client_commission?: string;
  convenience_fee?: string;
  gst_amount?: string;
  gst_percentage?: string;
  parking_fee?: string;
  processing_fee?: string;
  reseller_commission?: string;
  service_fee?: string;
  station_fee?: string;
  
  stopPending: boolean;
  wsActive: boolean;
  lastWsPing?: Date;
  
  transactionState?: string; // "Completed"
  stop_reason?: string;
  
  auth_tag?: string;
}

const ChargingSessionSchema: Schema = new Schema({
  charger_id: { type: String, required: true },
  connector_id: { type: Number, required: true },
  connector_type: { type: Number, default: 1 },
  session_id: { type: Number, required: true, unique: true },
  transaction_id: { type: Number },
  
  start_time: { type: Date, default: Date.now },
  stop_time: { type: Date },
  
  start_meter_value: { type: Number, default: 0 },
  current_meter_value: { type: Number, default: 0 },
  meter_stop: { type: Number },
  
  unit_consumed: { type: Number, default: 0 },
  price: { type: Number, default: 0 },
  unit_price: { type: Number, default: 0 },
  
  error_code: { type: String, default: 'NoError' },
  vendor_error_code: { type: String, default: 'NoVendorError' },
  
  location: { type: String },
  user_id: { type: Schema.Types.Mixed, required: true }, // Number or String
  email_id: { type: String },
  
  created_date: { type: Date, default: Date.now },
  modified_date: { type: Date, default: Date.now },
  
  status: { type: Boolean, default: true },
  charger_status: { type: String, default: 'Preparing' },
  
  amount_to_charge: { type: Number },
  consumed_amount: { type: Number, default: 0 },
  remaining_amount: { type: Number },
  
  // Fees (Strings as per example "0.00")
  EB_fee: { type: String, default: "0.00" },
  association_commission: { type: String, default: "0.00" },
  client_commission: { type: String, default: "0.00" },
  convenience_fee: { type: String, default: "0.00" },
  gst_amount: { type: String, default: "0.00" },
  gst_percentage: { type: String, default: "18" },
  parking_fee: { type: String, default: "0.00" },
  processing_fee: { type: String, default: "0.00" },
  reseller_commission: { type: String, default: "0.00" },
  service_fee: { type: String, default: "0.00" },
  station_fee: { type: String, default: "0.00" },
  
  stopPending: { type: Boolean, default: false },
  wsActive: { type: Boolean, default: true },
  lastWsPing: { type: Date },
  
  transactionState: { type: String },
  stop_reason: { type: String },
  
  auth_tag: { type: String }
});

// Middleware to update modified_date
ChargingSessionSchema.pre('save', function(this: IChargingSession) {
  this.modified_date = new Date();
});

export const ChargingSession = mongoose.model<IChargingSession>('ChargingSession', ChargingSessionSchema);
