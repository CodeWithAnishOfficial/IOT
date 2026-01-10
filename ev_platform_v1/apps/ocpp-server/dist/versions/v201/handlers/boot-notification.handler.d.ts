import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleBootNotification(connection: OCPPConnection, payload: any): Promise<{
    currentTime: string;
    interval: number;
    status: string;
}>;
