import { OCPPConnection } from '../../../core/connection.manager';
import { ChargingSession, Logger, RabbitMQService } from '@ev-platform-v1/shared';

const logger = new Logger('MeterValuesHandler');

export async function handleMeterValues(connection: OCPPConnection, payload: any) {
  const { connectorId, transactionId, meterValue } = payload;
  
  // Find active session
  const session = await ChargingSession.findOne({ transaction_id: transactionId });

  if (session) {
      const energyRegister = getSampledValue(meterValue, 'Energy.Active.Import.Register');
      const powerImport = getSampledValue(meterValue, 'Power.Active.Import');
      const soc = getSampledValue(meterValue, 'SoC');

      if (energyRegister !== null) {
          const currentEnergy = parseFloat(energyRegister);
          if (!isNaN(currentEnergy)) {
             session.total_energy = Math.max(0, currentEnergy - session.meter_start);
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
              energyConsumed: session.total_energy,
              power: powerImport ? parseFloat(powerImport) : 0,
              soc: soc ? parseFloat(soc) : null,
              timestamp: new Date()
          });
      } catch (err) {
          logger.error('Failed to publish charging_progress', err);
      }
  }
  
  return {};
}

function getSampledValue(meterValues: any[], measurand: string): string | null {
    if (!meterValues || !Array.isArray(meterValues)) return null;
    
    // Iterate over samples (usually latest is last, but payload might contain multiple samples)
    for (const meterValue of meterValues) {
        const sampledValues = meterValue.sampledValue;
        if (sampledValues && Array.isArray(sampledValues)) {
            for (const sample of sampledValues) {
                // Default measurand is Energy.Active.Import.Register if missing, but we look for explicit or implicit match
                const m = sample.measurand || 'Energy.Active.Import.Register';
                if (m === measurand) {
                    return sample.value;
                }
            }
        }
    }
    return null;
}
