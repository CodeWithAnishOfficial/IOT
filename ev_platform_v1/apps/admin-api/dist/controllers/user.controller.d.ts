import { Request, Response } from 'express';
export declare class AdminUserController {
    static getAllUsers(req: Request, res: Response): Promise<void>;
    static getUserDetails(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static toggleBlockUser(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static createUser(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static updateUser(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static deleteUser(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
