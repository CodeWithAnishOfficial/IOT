import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleStartTransaction(connection: OCPPConnection, payload: any): Promise<{
    transactionId: number;
    idTagInfo: {
        status: string;
    };
}>;
