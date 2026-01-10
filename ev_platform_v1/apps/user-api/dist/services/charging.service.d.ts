export declare class ChargingService {
    static startSession(userId: string, stationId: string, connectorId: string | number, amount: number, paymentDetails?: {
        orderId: string;
        paymentId: string;
        signature: string;
    }): Promise<{
        sessionId: number;
        status: string;
        message: string;
    }>;
    static stopSession(userEmail: string, sessionId: string): Promise<{
        status: string;
        message: string;
    }>;
    static checkConnectorStatus(stationId: string, connectorId: string | number, userId: string): Promise<{
        allowed: boolean;
        status: string;
        lock: string;
    }>;
    static releaseLock(stationId: string, connectorId: string | number, userId: string): Promise<{
        released: boolean;
        reason?: undefined;
    } | {
        released: boolean;
        reason: string;
    }>;
    static getHistory(userId: string): Promise<(import("mongoose").Document<unknown, {}, import("@ev-platform-v1/shared").IChargingSession, {}, import("mongoose").DefaultSchemaOptions> & import("@ev-platform-v1/shared").IChargingSession & Required<{
        _id: import("mongoose").Types.ObjectId;
    }> & {
        __v: number;
    })[]>;
    static getSessionDetails(userId: string, sessionId: string): Promise<import("mongoose").Document<unknown, {}, import("@ev-platform-v1/shared").IChargingSession, {}, import("mongoose").DefaultSchemaOptions> & import("@ev-platform-v1/shared").IChargingSession & Required<{
        _id: import("mongoose").Types.ObjectId;
    }> & {
        __v: number;
    }>;
}
