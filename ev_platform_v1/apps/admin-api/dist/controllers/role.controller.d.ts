import { Request, Response } from 'express';
export declare class RoleController {
    static getAllRoles(req: Request, res: Response): Promise<void>;
    static createRole(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateRole(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteRole(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
