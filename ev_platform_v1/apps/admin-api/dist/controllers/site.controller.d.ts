import { Request, Response } from 'express';
export declare class SiteController {
    static createSite(req: Request, res: Response): Promise<void>;
    static getAllSites(req: Request, res: Response): Promise<void>;
    static getSiteById(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateSite(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteSite(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static uploadImage(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
