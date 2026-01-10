import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleBootNotification(connection: OCPPConnection, payload: any): Promise<{
    status: string;
    currentTime: string;
    interval: number;
}>;
