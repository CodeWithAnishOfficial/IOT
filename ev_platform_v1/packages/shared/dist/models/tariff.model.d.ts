import mongoose, { Document } from 'mongoose';
export interface ITariff extends Document {
    name: string;
    type: 'FLAT' | 'TOU';
    currency: string;
    price_per_kwh: number;
    idle_fee_per_min?: number;
    peak_multiplier?: number;
    peak_hours?: Array<{
        start_time: string;
        end_time: string;
    }>;
    created_at: Date;
    updated_at: Date;
}
export declare const Tariff: mongoose.Model<ITariff, {}, {}, {}, mongoose.Document<unknown, {}, ITariff, {}, mongoose.DefaultSchemaOptions> & ITariff & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, ITariff>;
