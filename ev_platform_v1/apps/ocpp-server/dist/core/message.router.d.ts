import { OCPPConnection } from './connection.manager';
export declare class MessageRouter {
    static handleMessage(connection: OCPPConnection, message: any): Promise<void>;
}
