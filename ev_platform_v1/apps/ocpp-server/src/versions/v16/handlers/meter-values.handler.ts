import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService, MeterValue } from '@ev-platform-v1/shared';

const logger = new Logger('MeterValuesHandler');

export async function handleMeterValues(connection: OCPPConnection, payload: any) {
  const { connectorId, transactionId, meterValue } = payload;
  
  // Find active session
  const session = await ChargingSession.findOne({ transaction_id: transactionId });

  if (session) {
      if (meterValue && Array.isArray(meterValue)) {
          for (const mv of meterValue) {
             const timestamp = mv.timestamp;
             const sampledValues = mv.sampledValue || [];

             const voltage = getValue(sampledValues, 'Voltage');
             const currentImport = getValue(sampledValues, 'Current.Import');
             const powerImport = getValue(sampledValues, 'Power.Active.Import');
             const energyRegister = getValue(sampledValues, 'Energy.Active.Import.Register');
             const frequency = getValue(sampledValues, 'Frequency');
             const powerFactor = getValue(sampledValues, 'Power.Factor');
             const soc = getValue(sampledValues, 'SoC');

             // Create MeterValue Document matching the requested structure
             try {
                await MeterValue.create({
                    Voltage: voltage || "217.98",
                    Current: { Import: currentImport || "0.00" },
                    Power: { 
                        Active: { Import: powerImport || "0.00" },
                        Factor: powerFactor || "0.00"
                    },
                    Energy: {
                        Active: {
                            Import: { Register: energyRegister || "0" }
                        }
                    },
                    Frequency: frequency || "0",
                    charger_id: connection.id,
                    Timestamp: timestamp,
                    clientIP: connection.ip,
                    SessionID: session.session_id,
                    connectorId: connectorId
                });
             } catch (err) {
                 logger.error('Failed to save MeterValue', err);
             }

             // Update Session Logic
             if (energyRegister) {
                 const currentEnergy = parseFloat(energyRegister);
                 if (!isNaN(currentEnergy)) {
                     // Update unit_consumed and current_meter_value
                     session.unit_consumed = Math.max(0, currentEnergy - session.start_meter_value);
                     session.current_meter_value = currentEnergy;
                     await session.save();
                 }
             }

             // Publish Progress
              try {
                  const rabbit = RabbitMQService.getInstance();
                  await rabbit.publish('charging_progress', {
                      sessionId: session.session_id,
                      userId: session.user_id,
                      transactionId,
                      energyConsumed: session.unit_consumed,
                      power: powerImport ? parseFloat(powerImport) : 0,
                      soc: soc ? parseFloat(soc) : null,
                      timestamp: new Date()
                  });
              } catch (err) {
                  logger.error('Failed to publish charging_progress', err);
              }
          }
      }
  } else {
      logger.warn(`MeterValues received for unknown transaction ${transactionId}`);
  }
  
  return {};
}

function getValue(sampledValues: any[], measurand: string): string | null {
    if (!sampledValues) return null;
    const sample = sampledValues.find((s: any) => (s.measurand || 'Energy.Active.Import.Register') === measurand);
    return sample ? String(sample.value) : null;
}
