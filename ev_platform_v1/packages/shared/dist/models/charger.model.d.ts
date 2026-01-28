import mongoose, { Document } from 'mongoose';
export interface ICharger extends Document {
    charger_id: string;
    name?: string;
    location?: {
        lat: number;
        lng: number;
        address?: string;
    };
    status: 'online' | 'offline' | 'charging' | 'faulted';
    max_power_kw: number;
    tariff_id?: string;
    site_id?: string;
    vendor?: string;
    modelName?: string;
    firmware_version?: string;
    serial_number?: string;
    ip_address?: string;
    ocpp_username?: string;
    ocpp_password?: string;
    owner_id?: number;
    is_public?: boolean;
    price_per_kwh?: number;
    connectors: Array<{
        connector_id: number;
        status: string;
        type: string;
        max_power_kw?: number;
    }>;
    created_at: Date;
    updated_at: Date;
}
export declare const Charger: mongoose.Model<ICharger, {}, {}, {}, mongoose.Document<unknown, {}, ICharger, {}, mongoose.DefaultSchemaOptions> & ICharger & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, ICharger>;
