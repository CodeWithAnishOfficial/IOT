import { Request, Response } from 'express';
export declare class AdminSavedTripController {
    static getAllSavedTrips(req: Request, res: Response): Promise<void>;
    static getSavedTripDetails(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
