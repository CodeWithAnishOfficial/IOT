import mongoose, { Schema, Document } from 'mongoose';

export interface ISupportTicket extends Document {
  ticket_id: string;
  user_id: string;
  subject: string;
  description: string;
  status: 'Open' | 'In Progress' | 'Resolved' | 'Closed';
  priority: 'Low' | 'Medium' | 'High';
  category: 'Billing' | 'Technical' | 'General' | 'Other';
  responses: Array<{
    sender: 'user' | 'admin';
    message: string;
    timestamp: Date;
  }>;
  created_at: Date;
  updated_at: Date;
}

const SupportTicketSchema: Schema = new Schema({
  ticket_id: { type: String, required: true, unique: true },
  user_id: { type: String, required: true },
  subject: { type: String, required: true },
  description: { type: String, required: true },
  status: { type: String, enum: ['Open', 'In Progress', 'Resolved', 'Closed'], default: 'Open' },
  priority: { type: String, enum: ['Low', 'Medium', 'High'], default: 'Medium' },
  category: { type: String, enum: ['Billing', 'Technical', 'General', 'Other'], default: 'General' },
  responses: [{
    sender: { type: String, enum: ['user', 'admin'] },
    message: { type: String },
    timestamp: { type: Date, default: Date.now }
  }],
  created_at: { type: Date, default: Date.now },
  updated_at: { type: Date, default: Date.now }
});

export const SupportTicket = mongoose.model<ISupportTicket>('SupportTicket', SupportTicketSchema);
