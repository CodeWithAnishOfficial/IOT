export declare class RedisService {
    private static instance;
    private pub;
    private sub;
    private logger;
    private constructor();
    static getInstance(): RedisService;
    publish(channel: string, message: any): Promise<void>;
    subscribe(channel: string, callback: (message: any) => void): Promise<void>;
    sendCommand(chargerId: string, command: string, payload: any): Promise<void>;
    set(key: string, value: any, ttlSeconds?: number): Promise<void>;
    get(key: string): Promise<any | null>;
    del(key: string): Promise<void>;
}
