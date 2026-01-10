import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleStopTransaction(connection: OCPPConnection, payload: any): Promise<{
    idTagInfo: {
        status: string;
    };
}>;
