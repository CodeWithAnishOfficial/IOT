import { Request, Response } from 'express';
export declare class ChargerController {
    static getAllChargers(req: Request, res: Response): Promise<void>;
    static createCharger(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static getChargerById(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateCharger(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteCharger(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
