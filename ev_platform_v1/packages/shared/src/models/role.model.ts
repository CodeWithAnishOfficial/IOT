import mongoose, { Schema, Document } from 'mongoose';

export interface IRole extends Document {
  role_id: number;
  role_name: string;
  description?: string;
  created_at: Date;
  updated_at: Date;
}

const RoleSchema: Schema = new Schema({
  role_id: { type: Number, required: true, unique: true },
  role_name: { type: String, required: true, unique: true },
  description: { type: String },
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now }
});

export const Role = mongoose.model<IRole>('Role', RoleSchema);
