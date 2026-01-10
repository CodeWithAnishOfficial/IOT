import { Request, Response } from 'express';
export declare class AdminSupportController {
    static getAllTickets(req: Request, res: Response): Promise<void>;
    static updateTicketStatus(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static addReply(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
