import { Request, Response } from 'express';
export declare class WalletController {
    static getBalance(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static addMoney(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static verifyPayment(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getTransactions(req: Request, res: Response): Promise<void>;
    static requestRefund(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
