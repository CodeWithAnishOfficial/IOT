import { Request, Response } from 'express';
export declare class AuthController {
    static generateOTP(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static initiateRegistration(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static verifyOTP(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static passwordLogin(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
    static googleSignIn(req: Request, res: Response): Promise<Response<any, Record<string, any>> | undefined>;
}
