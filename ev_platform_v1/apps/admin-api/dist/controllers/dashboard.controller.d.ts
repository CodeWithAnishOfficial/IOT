import { Request, Response } from 'express';
export declare class DashboardController {
    static getStats(req: Request, res: Response): Promise<void>;
    static getAnalytics(req: Request, res: Response): Promise<void>;
    static getRecentActivity(req: Request, res: Response): Promise<void>;
}
