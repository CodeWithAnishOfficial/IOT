import mongoose, { Schema, Document } from 'mongoose';

export interface ISite extends Document {
  name: string;
  address: string;
  city: string;
  state?: string;
  zip_code?: string;
  country: string;
  location: {
    lat: number;
    lng: number;
  };
  images?: string[];
  facilities?: string[]; // e.g. ['Wifi', 'Cafe', 'Restroom']
  contact_number?: string;
  created_at: Date;
  updated_at: Date;
}

const SiteSchema: Schema = new Schema({
  name: { type: String, required: true },
  address: { type: String, required: true },
  city: { type: String, required: true },
  state: { type: String },
  zip_code: { type: String },
  country: { type: String, default: 'India' },
  location: {
    lat: { type: Number, required: true },
    lng: { type: Number, required: true }
  },
  images: [{ type: String }],
  facilities: [{ type: String }],
  contact_number: { type: String },
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now }
});

export const Site = mongoose.model<ISite>('Site', SiteSchema);
