import mongoose, { Schema, Document } from 'mongoose';

export interface IChargingStation extends Document {
  charger_id: string;
  name?: string;
  location?: {
    lat: number;
    lng: number;
    address?: string;
  };
  status: 'online' | 'offline' | 'charging' | 'faulted';
  max_power_kw: number;
  tariff_id?: string; // Reference to Tariff
  site_id?: string; // Reference to Site
  
  // Device Details
  vendor?: string;
  modelName?: string;
  firmware_version?: string;
  serial_number?: string;
  
  // Security / Connectivity
  ip_address?: string;
  ocpp_username?: string; // Usually same as charger_id
  ocpp_password?: string; // Basic Auth Password / Secret Key
  
  connectors: Array<{
    connector_id: number;
    status: string;
    type: string;
    max_power_kw?: number;
  }>;
  created_at: Date;
  updated_at: Date;
}

const ChargingStationSchema: Schema = new Schema({
  charger_id: { type: String, required: true, unique: true },
  name: { type: String },
  location: {
    lat: { type: Number },
    lng: { type: Number },
    address: { type: String }
  },
  status: { type: String, enum: ['online', 'offline', 'charging', 'faulted'], default: 'offline' },
  max_power_kw: { type: Number, default: 22.0 }, // Default 22kW station
  tariff_id: { type: String }, // Optional tariff reference
  site_id: { type: String }, // Optional site reference
  
  // Device Details
  vendor: { type: String },
  modelName: { type: String },
  firmware_version: { type: String },
  serial_number: { type: String },
  
  // Security
  ip_address: { type: String },
  ocpp_username: { type: String },
  ocpp_password: { type: String }, // Should be hashed in prod, but keeping plain for display if requested

  connectors: [{
    connector_id: { type: Number, required: true },
    status: { type: String, default: 'Available' },
    type: { type: String },
    max_power_kw: { type: Number, default: 22.0 }
  }],
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now }
});

export const ChargingStation = mongoose.model<IChargingStation>('ChargingStation', ChargingStationSchema);
