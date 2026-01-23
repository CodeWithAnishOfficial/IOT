import mongoose, { Document } from 'mongoose';
export interface ISavedTrip extends Document {
    trip_id: number;
    user_id: number;
    name: string;
    source: {
        address: string;
        lat: number;
        lng: number;
    };
    destination: {
        address: string;
        lat: number;
        lng: number;
    };
    stops: Array<{
        charger_id: string;
        name: string;
        address: string;
        location: {
            address: string;
            lat: number;
            lng: number;
        };
    }>;
    createdAt: Date;
}
declare const _default: mongoose.Model<ISavedTrip, {}, {}, {}, mongoose.Document<unknown, {}, ISavedTrip, {}, mongoose.DefaultSchemaOptions> & ISavedTrip & Required<{
    _id: mongoose.Types.ObjectId;
}> & {
    __v: number;
}, any, ISavedTrip>;
export default _default;
