import mongoose, { Document } from 'mongoose';
export interface IRole extends Document {
    role_id: number;
    role_name: string;
    description?: string;
    created_at: Date;
    updated_at: Date;
}
export declare const Role: mongoose.Model<IRole, {}, {}, {}, mongoose.Document<unknown, {}, IRole, {}, mongoose.DefaultSchemaOptions> & IRole & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IRole>;
