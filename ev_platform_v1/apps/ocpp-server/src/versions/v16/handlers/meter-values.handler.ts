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

             const voltageSample = getSample(sampledValues, 'Voltage');
             const currentImportSample = getSample(sampledValues, 'Current.Import');
             const powerImportSample = getSample(sampledValues, 'Power.Active.Import');
             const energyRegisterSample = getSample(sampledValues, 'Energy.Active.Import.Register');
             const frequencySample = getSample(sampledValues, 'Frequency');
             const powerFactorSample = getSample(sampledValues, 'Power.Factor');
             const socSample = getSample(sampledValues, 'SoC');

             const voltage = voltageSample?.value;
             const currentImport = currentImportSample?.value;
             const powerImport = powerImportSample?.value;
             const energyRegister = energyRegisterSample?.value;
             const frequency = frequencySample?.value;
             const powerFactor = powerFactorSample?.value;
             const soc = socSample?.value;

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
             let shouldSave = false;

             if (energyRegister) {
                 const currentEnergy = parseFloat(energyRegister);
                 if (!isNaN(currentEnergy)) {
                     const unit = energyRegisterSample?.unit || 'Wh';
                     
                     // Helper to normalize to Wh
                     const toWh = (val: number, u: string) => {
                         if (!u) return val; // Assume Wh if no unit
                         if (u.toLowerCase() === 'kwh' || u.toLowerCase() === 'kw') return val * 1000;
                         return val;
                     };

                     // Normalize both current reading and start reading to Wh before subtracting
                     const currentWh = toWh(currentEnergy, unit);
                     
                     // Start Meter Value is always in Wh (OCPP 1.6 StartTransaction spec)
                     // So we do NOT convert it using the current unit
                     const startWh = session.start_meter_value;

                     const deltaWh = Math.max(0, currentWh - startWh);
                     
                     logger.info(`MV Calc: Start=${startWh}Wh, Current=${currentEnergy} ${unit} -> ${currentWh}Wh, Delta=${deltaWh}Wh`);

                     // Update unit_consumed (Always in Wh) and current_meter_value (Raw)
                     session.unit_consumed = deltaWh;
                     session.current_meter_value = currentEnergy;
                     
                     // Update Cost based on unit_price
                     if (session.unit_price) {
                        // Cost calculation uses kWh
                        const kwhConsumption = deltaWh / 1000.0;
                        session.consumed_amount = kwhConsumption * session.unit_price;
                        session.price = session.consumed_amount; 
                     }
                     
                     shouldSave = true;
                 }
             }

             // SOC Calculation Strategy
             // If Prepaid (amount_to_charge > 0): Calculate 'Session Progress' as SOC
             // If Postpaid: Use Charger's SOC
             
             const chargerSoc = soc ? parseFloat(soc) : null;
             
             if (session.amount_to_charge && session.amount_to_charge > 0) {
                 // Prepaid Logic
                 const currentCost = session.consumed_amount || 0;
                 let calculatedSoc = (currentCost / session.amount_to_charge) * 100;
                 
                 // Clamp 0-100
                 if (calculatedSoc > 100) calculatedSoc = 100;
                 if (calculatedSoc < 0) calculatedSoc = 0;
                 
                 const newSoc = parseFloat(calculatedSoc.toFixed(1));
                 if (session.soc !== newSoc) {
                     session.soc = newSoc;
                     shouldSave = true;
                 }
             } else if (chargerSoc !== null) {
                 // Postpaid Logic: Update only if charger sends SOC
                 if (session.soc !== chargerSoc) {
                     session.soc = chargerSoc;
                     shouldSave = true;
                 }
             }

             if (shouldSave) {
                 await session.save();
             }

             // Publish Progress
              try {
                  const rabbit = RabbitMQService.getInstance();
                  
                  // Normalize Power to W (for Frontend)
                  let powerForApp = powerImport ? parseFloat(powerImport) : 0;
                  const powerUnit = powerImportSample?.unit || 'W';
                  if (powerUnit.toLowerCase() === 'kw') {
                      powerForApp = powerForApp * 1000;
                  }

                  // Use email_id as userId because User-API uses email for WS identification
                  await rabbit.publish('charging_progress', {
                      sessionId: session.session_id,
                      userId: session.email_id, 
                      transactionId,
                      energyConsumed: session.unit_consumed, // Already normalized to Wh
                      power: powerForApp,
                      voltage: voltage ? parseFloat(voltage) : 0,
                      current: currentImport ? parseFloat(currentImport) : 0,
                      cost: session.consumed_amount || 0,
                      soc: session.soc || 0,
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

function getSample(sampledValues: any[], measurand: string): any {
    if (!sampledValues) return null;
    return sampledValues.find((s: any) => (s.measurand || 'Energy.Active.Import.Register') === measurand) || null;
}
