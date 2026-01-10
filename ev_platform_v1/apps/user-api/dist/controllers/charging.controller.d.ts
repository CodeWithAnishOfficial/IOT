import { Request, Response } from 'express';
export declare class ChargingController {
    static getHistory(req: Request, res: Response): Promise<void>;
    static downloadInvoice(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static initiatePayment(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static start(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static stop(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static checkStatus(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static releaseLock(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
