import { Connection } from 'mongoose';
export declare class Database {
    private static instance;
    private connection;
    private logger;
    private constructor();
    static getInstance(): Database;
    connect(uri: string): Promise<Connection>;
    disconnect(): Promise<void>;
    getConnection(): Connection | null;
}
