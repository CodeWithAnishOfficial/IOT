import { Request, Response } from 'express';
export declare class AnalyticsController {
    static getUserAnalytics(req: Request, res: Response): Promise<void>;
    static getChargerAnalytics(req: Request, res: Response): Promise<void>;
    static getUserDetailAnalytics(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
