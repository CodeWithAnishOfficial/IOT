import { Application } from 'express';
export declare class App {
    app: Application;
    private port;
    private logger;
    constructor(port: number);
    private initializeMiddlewares;
    private initializeRoutes;
    start(): void;
}
