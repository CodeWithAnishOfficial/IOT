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
        activeSession: boolean;
        sessionId: number;
        message: string;
        status?: undefined;
        lock?: undefined;
    } | {
        allowed: boolean;
        status: string;
        lock: string;
        activeSession?: undefined;
        sessionId?: undefined;
        message?: undefined;
    }>;
    static releaseLock(stationId: string, connectorId: string | number, userId: string): Promise<{
        released: boolean;
        reason?: undefined;
    } | {
        released: boolean;
        reason: string;
    }>;
    static getActiveSession(userId: string): Promise<(import("mongoose").Document<unknown, {}, import("@ev-platform-v1/shared").IChargingSession, {}, import("mongoose").DefaultSchemaOptions> & import("@ev-platform-v1/shared").IChargingSession & Required<{
        _id: import("mongoose").Types.ObjectId;
    }> & {
        __v: number;
    }) | {
        chargerDetails: {
            charger_id: string;
            max_power_kw: number | undefined;
            connector_type: string;
            name: string | undefined;
            address: string | undefined;
        };
        charger_id: string;
        connector_id: number;
        connector_type?: number;
        session_id: number;
        transaction_id?: number;
        start_time: Date;
        stop_time?: Date;
        start_meter_value: number;
        current_meter_value?: number;
        meter_stop?: number;
        unit_consumed: number;
        price: number;
        unit_price: number;
        error_code: string;
        vendor_error_code: string;
        location?: string;
        user_id: string | number;
        email_id?: string;
        created_date: Date;
        modified_date: Date;
        status: boolean;
        charger_status: string;
        amount_to_charge?: number;
        consumed_amount: number;
        remaining_amount?: number;
        EB_fee?: string;
        association_commission?: string;
        client_commission?: string;
        convenience_fee?: string;
        gst_amount?: string;
        gst_percentage?: string;
        parking_fee?: string;
        processing_fee?: string;
        reseller_commission?: string;
        service_fee?: string;
        station_fee?: string;
        stopPending: boolean;
        wsActive: boolean;
        lastWsPing?: Date;
        transactionState?: string;
        stop_reason?: string;
        soc?: number;
        auth_tag?: string;
        _id: import("mongoose").Types.ObjectId;
        $locals: Record<string, unknown>;
        $op: "save" | "validate" | "remove" | null;
        $where: Record<string, unknown>;
        baseModelName?: string;
        collection: import("mongoose").Collection;
        db: import("mongoose").Connection;
        errors?: import("mongoose").Error.ValidationError;
        isNew: boolean;
        schema: import("mongoose").Schema;
        __v: number;
    } | null>;
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
