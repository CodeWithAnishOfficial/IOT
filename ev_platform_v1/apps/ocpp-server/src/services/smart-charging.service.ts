import { Charger, ChargingSession, Logger, RedisService } from '@ev-platform-v1/shared';
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
      const station = await Charger.findOne({ charger_id: chargerId });
      
      if (!station) {
        logger.warn(`Station ${chargerId} not found for smart charging`);
        return;
      }

      const maxStationPower = station.max_power_kw || 22.0; // Default if not set

      // Get all active sessions for this charger
      const activeSessions = await ChargingSession.find({
        charger_id: chargerId,
        status: true
      });

      // Dedup connector IDs using Set
      const activeConnectorIds = Array.from(new Set(activeSessions.map(s => s.connector_id)));
      
      // Add current connector if not already in list
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
      for (const cid of activeConnectorIds) {
          await this.sendChargingProfile(connection, cid, allocatedPower);
      }

    } catch (error) {
      logger.error(`Error applying load balancing for ${connection.id}`, error);
    }
  }

  private static async sendChargingProfile(connection: OCPPConnection, connectorId: number, powerLimitKw: number) {
      // Convert kW to Amps (Approximation: 3-phase 400V)
      // Amps = (kW * 1000) / (400 * 1.732)
      
      let amps = Math.floor((powerLimitKw * 1000) / (400 * 1.732));

      // Enforce minimum charging current (usually 6A)
      if (amps < 6) {
          amps = 6;
      }

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
      
      connection.send([2, requestId, 'SetChargingProfile', profile]);
      logger.info(`Sent limit ${amps}A (${powerLimitKw}kW) to connector ${connectorId}`);
  }
}
