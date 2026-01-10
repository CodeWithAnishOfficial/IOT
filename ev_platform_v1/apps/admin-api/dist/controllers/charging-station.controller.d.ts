import { Request, Response } from 'express';
export declare class ChargingStationController {
    static getAllStations(req: Request, res: Response): Promise<void>;
    static createStation(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getStationById(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateStation(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteStation(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
