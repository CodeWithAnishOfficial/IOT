import mongoose, { Document } from 'mongoose';
export interface IVehicle extends Document {
    user_id: string;
    make: string;
    modelName: string;
    year: number;
    vin?: string;
    plate_no?: string;
    connector_type: 'Type2' | 'CCS2' | 'Chademo' | 'GB/T';
    is_default: boolean;
    created_at: Date;
}
export declare const Vehicle: mongoose.Model<IVehicle, {}, {}, {}, mongoose.Document<unknown, {}, IVehicle, {}, mongoose.DefaultSchemaOptions> & IVehicle & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IVehicle>;
