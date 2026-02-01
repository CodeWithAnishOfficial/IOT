"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleMeterValues = handleMeterValues;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('MeterValuesHandler');
async function handleMeterValues(connection, payload) {
    const { connectorId, transactionId, meterValue } = payload;
    // Find active session
    const session = await shared_1.ChargingSession.findOne({ transaction_id: transactionId });
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
                    await shared_1.MeterValue.create({
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
                }
                catch (err) {
                    logger.error('Failed to save MeterValue', err);
                }
                // Update Session Logic
                let shouldSave = false;
                if (soc) {
                    session.soc = parseFloat(soc);
                    shouldSave = true;
                }
                if (energyRegister) {
                    const currentEnergy = parseFloat(energyRegister);
                    if (!isNaN(currentEnergy)) {
                        const unit = energyRegisterSample?.unit || 'Wh';
                        const rawDelta = Math.max(0, currentEnergy - session.start_meter_value);
                        // Normalize delta to Wh for storage consistency
                        let deltaWh = rawDelta;
                        if (unit.toLowerCase() === 'kwh' || unit.toLowerCase() === 'kw') {
                            deltaWh = rawDelta * 1000;
                        }
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
                // Fallback: If SoC is not provided by charger, calculate it based on amount_to_charge (Simulation)
                if (!session.soc && session.amount_to_charge && session.unit_price && session.unit_price > 0) {
                    const maxEnergy = session.amount_to_charge / session.unit_price; // kWh
                    if (maxEnergy > 0) {
                        const currentKwh = session.unit_consumed / 1000.0;
                        let calculatedSoc = (currentKwh / maxEnergy) * 100;
                        // Clamp 0-100
                        if (calculatedSoc > 100)
                            calculatedSoc = 100;
                        if (calculatedSoc < 0)
                            calculatedSoc = 0;
                        session.soc = parseFloat(calculatedSoc.toFixed(1));
                        shouldSave = true;
                    }
                }
                if (shouldSave) {
                    await session.save();
                }
                // Publish Progress
                try {
                    const rabbit = shared_1.RabbitMQService.getInstance();
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
                }
                catch (err) {
                    logger.error('Failed to publish charging_progress', err);
                }
            }
        }
    }
    else {
        logger.warn(`MeterValues received for unknown transaction ${transactionId}`);
    }
    return {};
}
function getSample(sampledValues, measurand) {
    if (!sampledValues)
        return null;
    return sampledValues.find((s) => (s.measurand || 'Energy.Active.Import.Register') === measurand) || null;
}
//# sourceMappingURL=meter-values.handler.js.map