import { Request, Response } from 'express';
export declare class AdminAuthController {
    static login(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static me(req: Request, res: Response): Promise<void>;
}
