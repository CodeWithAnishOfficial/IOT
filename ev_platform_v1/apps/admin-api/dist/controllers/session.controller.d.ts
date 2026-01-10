import { Request, Response } from 'express';
export declare class AdminSessionController {
    static getAllSessions(req: Request, res: Response): Promise<void>;
    static getSessionDetails(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
