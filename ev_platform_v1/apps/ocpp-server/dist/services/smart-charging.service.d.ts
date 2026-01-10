import { OCPPConnection } from '../core/connection.manager';
export declare class SmartChargingService {
    /**
     * Check if a new transaction can start or if we need to load balance.
     * If load balancing is needed, it calculates new limits and sends SetChargingProfile.
     *
     * @param connection The OCPP connection
     * @param connectorId The connector where transaction is starting
     */
    static applyLoadBalancing(connection: OCPPConnection, connectorId: number): Promise<void>;
    private static sendChargingProfile;
}
