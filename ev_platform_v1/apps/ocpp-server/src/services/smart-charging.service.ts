import { ChargingStation, ChargingSession, Logger, RedisService } from '@ev-platform-v1/shared';
import { OCPPConnection } from '../core/connection.manager';

const logger = new Logger('SmartChargingService');

export class SmartChargingService {
  /**
   * Check if a new transaction can start or if we need to load balance.
   * If load balancing is needed, it calculates new limits and sends SetChargingProfile.
   * 
   * @param connection The OCPP connection
   * @param connectorId The connector where transaction is starting
   */
  static async applyLoadBalancing(connection: OCPPConnection, connectorId: number) {
    try {
      const chargerId = connection.id;
      const station = await ChargingStation.findOne({ charger_id: chargerId });
      
      if (!station) {
        logger.warn(`Station ${chargerId} not found for smart charging`);
        return;
      }

      const maxStationPower = station.max_power_kw || 22.0; // Default if not set

      // Get all active sessions for this charger
      const activeSessions = await ChargingSession.find({
        charger_id: chargerId,
        status: 'active'
      });

      const activeConnectorIds = activeSessions.map(s => s.connector_id);
      // Add current connector if not already in list (it might not be saved as active yet in DB depending on timing)
      if (!activeConnectorIds.includes(connectorId)) {
        activeConnectorIds.push(connectorId);
      }

      const activeCount = activeConnectorIds.length;
      if (activeCount === 0) return;

      // Simple Fair Share Logic
      // Allocated Power = Station Max Power / Number of Active Connectors
      const allocatedPower = Math.floor((maxStationPower / activeCount) * 10) / 10; // Round down to 1 decimal

      logger.info(`Load Balancing for ${chargerId}: Active=${activeCount}, Max=${maxStationPower}kW, Alloc=${allocatedPower}kW`);

      // Send SetChargingProfile to ALL active connectors
      // In a real scenario, we might only update if the new allocation is significantly different
      // or if we are the ones starting the transaction.
      
      for (const cid of activeConnectorIds) {
          await this.sendChargingProfile(connection, cid, allocatedPower);
      }

    } catch (error) {
      logger.error(`Error applying load balancing for ${connection.id}`, error);
    }
  }

  private static async sendChargingProfile(connection: OCPPConnection, connectorId: number, powerLimitKw: number) {
      // Convert kW to Amps (Approximation: 3-phase 400V or 1-phase 230V?)
      // Assuming 3-phase 400V for commercial chargers. P = V * I * sqrt(3)
      // I = P / (V * sqrt(3)) -> I = (PowerKw * 1000) / (400 * 1.732)
      // Example: 11kW -> ~16A. 22kW -> ~32A.
      // Let's use a standard conversion factor or just use Ampere if station supports it.
      // OCPP usually uses TxProfile with limits in Amps or Watts.
      
      // Let's assume P = V * I (Single phase) or P = 3 * V * I (Three phase)
      // For simplicity, let's assume 230V single phase or 3-phase equivalent per phase amps.
      // 11kW 3-phase => 16A per phase. 
      // 7.4kW 1-phase => 32A.
      
      // Let's assume we want to limit Amps. 
      // If we don't know the phase config, we might default to a safe assumption or configuration.
      // Let's assume 3-phase 400V roughly.
      // Amps = (kW * 1000) / (400 * 1.732)
      
      const amps = Math.floor((powerLimitKw * 1000) / (400 * 1.732));

      const profile = {
          connectorId: connectorId,
          csChargingProfiles: {
              chargingProfileId: 1, // Fixed ID for simplicity
              stackLevel: 1,
              chargingProfilePurpose: 'TxProfile',
              chargingProfileKind: 'Absolute',
              chargingSchedule: {
                  chargingRateUnit: 'A',
                  chargingSchedulePeriod: [
                      {
                          startPeriod: 0,
                          limit: amps,
                          numberPhases: 3
                      }
                  ]
              }
          }
      };
      
      const requestId = Date.now().toString();
      // Send SetChargingProfile (Action: SetChargingProfile)
      // Note: This requires the router to handle the response, or we send generic request
      // We can use connection.send directly as a request
      
      connection.send([2, requestId, 'SetChargingProfile', profile]);
      logger.info(`Sent limit ${amps}A (${powerLimitKw}kW) to connector ${connectorId}`);
  }
}
