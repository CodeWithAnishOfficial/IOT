import { Request, Response } from 'express';
export declare class TariffController {
    static createTariff(req: Request, res: Response): Promise<void>;
    static getAllTariffs(req: Request, res: Response): Promise<void>;
    static updateTariff(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteTariff(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
