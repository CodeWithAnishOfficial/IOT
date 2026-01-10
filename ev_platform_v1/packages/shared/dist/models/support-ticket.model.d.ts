import mongoose, { Document } from 'mongoose';
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
export declare const SupportTicket: mongoose.Model<ISupportTicket, {}, {}, {}, mongoose.Document<unknown, {}, ISupportTicket, {}, mongoose.DefaultSchemaOptions> & ISupportTicket & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, ISupportTicket>;
