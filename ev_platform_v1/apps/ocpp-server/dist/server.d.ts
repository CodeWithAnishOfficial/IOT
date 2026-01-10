export declare class OCPPServer {
    private port;
    private wss;
    private logger;
    private connectionManager;
    private redis;
    private httpServer;
    constructor(port: number);
    private initializeRedisListeners;
    start(): Promise<void>;
    private processMessage;
    stop(): void;
}
