import mongoose, { Schema, Document } from 'mongoose';

export interface ISavedTrip extends Document {
  trip_id: number; // Numeric ID
  user_id: number; // Numeric ID
  name: string;
  source: {
    address: string;
    lat: number;
    lng: number;
  };
  destination: {
    address: string;
    lat: number;
    lng: number;
  };
  stops: Array<{
    charger_id: string;
    name: string;
    address: string;
    location: {
        address: string;
        lat: number;
        lng: number;
    };
  }>;
  createdAt: Date;
}

const SavedTripSchema: Schema = new Schema({
  trip_id: { type: Number, required: true, unique: true, index: true },
  user_id: { type: Number, required: true, index: true },
  name: { type: String, required: true },
  source: {
    address: { type: String, required: true },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  destination: {
    address: { type: String, required: true },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
  },
  stops: [{
    charger_id: { type: String },
    name: { type: String },
    address: { type: String },
    location: {
        address: { type: String },
        lat: { type: Number },
        lng: { type: Number },
    }
  }],
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model<ISavedTrip>('SavedTrip', SavedTripSchema);
