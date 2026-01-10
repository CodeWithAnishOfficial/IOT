import { OCPPConnection } from '../../core/connection.manager';
export declare class RouterV201 {
    static handleRequest(connection: OCPPConnection, action: string, payload: any, requestId: string): Promise<void>;
}
