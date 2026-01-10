import mongoose, { Document } from 'mongoose';
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
    facilities?: string[];
    contact_number?: string;
    tariff_id?: string;
    created_at: Date;
    updated_at: Date;
}
export declare const Site: mongoose.Model<ISite, {}, {}, {}, mongoose.Document<unknown, {}, ISite, {}, mongoose.DefaultSchemaOptions> & ISite & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, ISite>;
