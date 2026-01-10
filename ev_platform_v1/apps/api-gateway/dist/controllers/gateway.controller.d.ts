import { Request, Response } from 'express';
export declare class GatewayController {
    static healthCheck(req: Request, res: Response): void;
    static getMetrics(req: Request, res: Response): Promise<void>;
}
