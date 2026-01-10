import { Request, Response } from 'express';
export declare class VehicleController {
    static addVehicle(req: Request, res: Response): Promise<void>;
    static getVehicles(req: Request, res: Response): Promise<void>;
    static deleteVehicle(req: Request, res: Response): Promise<void>;
}
