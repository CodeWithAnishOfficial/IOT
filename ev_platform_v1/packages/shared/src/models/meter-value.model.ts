import mongoose, { Schema, Document } from 'mongoose';

export interface IMeterValue extends Document {
  Voltage: string;
  Current: {
    Import: string;
  };
  Power: {
    Active: {
      Import: string;
    };
    Factor: string;
  };
  Energy: {
    Active: {
      Import: {
        Register: string;
      };
    };
  };
  Frequency: string;
  charger_id: string;
  Timestamp: string;
  clientIP: string;
  SessionID: number;
  connectorId: number;
  
  // Optional: Allow flexibility
  [key: string]: any;
}

const MeterValueSchema: Schema = new Schema({
  Voltage: { type: String, default: "0.00" },
  Current: {
    Import: { type: String, default: "0.00" }
  },
  Power: {
    Active: {
      Import: { type: String, default: "0.00" }
    },
    Factor: { type: String, default: "0.00" }
  },
  Energy: {
    Active: {
      Import: {
        Register: { type: String, default: "0" }
      }
    }
  },
  Frequency: { type: String, default: "0" },
  charger_id: { type: String, required: true },
  Timestamp: { type: String, required: true },
  clientIP: { type: String },
  SessionID: { type: Number, required: true },
  connectorId: { type: Number, required: true }
}, { strict: false }); // strict: false allows saving other fields if necessary

export const MeterValue = mongoose.model<IMeterValue>('MeterValue', MeterValueSchema);
