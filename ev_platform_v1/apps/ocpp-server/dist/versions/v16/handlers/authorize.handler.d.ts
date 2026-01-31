import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleAuthorize(connection: OCPPConnection, payload: any): Promise<{
    idTagInfo: {
        status: string;
        expiryDate: string;
        parentIdTag: null;
    };
} | {
    idTagInfo: {
        status: string;
        parentIdTag: null;
        expiryDate?: undefined;
    };
}>;
