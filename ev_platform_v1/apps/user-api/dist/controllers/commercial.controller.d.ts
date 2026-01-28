import { Request, Response } from 'express';
export declare class CommercialController {
    static addCharger(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getMyChargers(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getAnalytics(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
    static getWalletHistory(req: Request, res: Response): Promise<Response<any, Record<string, any>>>;
}
