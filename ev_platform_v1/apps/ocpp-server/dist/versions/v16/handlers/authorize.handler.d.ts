import { OCPPConnection } from '../../../core/connection.manager';
export declare function handleAuthorize(connection: OCPPConnection, payload: any): Promise<{
    idTagInfo: {
        status: string;
        parentIdTag: null;
        expiryDate?: undefined;
    };
} | {
    idTagInfo: {
        status: string;
        expiryDate: string;
        parentIdTag: null;
    };
}>;
