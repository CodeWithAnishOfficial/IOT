import mongoose, { Document } from 'mongoose';
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
    [key: string]: any;
}
export declare const MeterValue: mongoose.Model<IMeterValue, {}, {}, {}, mongoose.Document<unknown, {}, IMeterValue, {}, mongoose.DefaultSchemaOptions> & IMeterValue & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, IMeterValue>;
