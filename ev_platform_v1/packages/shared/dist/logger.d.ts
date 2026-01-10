export declare class Logger {
    private serviceName;
    constructor(serviceName: string);
    info(message: string, meta?: any): void;
    error(message: string, error?: any): void;
    warn(message: string, meta?: any): void;
}
