import { Request, Response } from 'express';
export declare class SupportController {
    static createTicket(req: Request, res: Response): Promise<void>;
    static getMyTickets(req: Request, res: Response): Promise<void>;
    static addReply(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
