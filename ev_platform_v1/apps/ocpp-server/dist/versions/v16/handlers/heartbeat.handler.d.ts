import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleHeartbeat(connection: OCPPConnection, payload: any): Promise<{
    currentTime: string;
}>;
