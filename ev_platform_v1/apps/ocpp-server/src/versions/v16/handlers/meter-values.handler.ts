import { OCPPConnection } from '../../../core/connection.manager';
import { Logger } from '@ev-platform-v1/shared';

const logger = new Logger('MeterValuesHandler');

export async function handleMeterValues(connection: OCPPConnection, payload: any) {
  const { connectorId, transactionId, meterValue } = payload;
  // logger.info(`MeterValues from ${connection.id}`, meterValue);
  
  // TODO: Store meter values if needed (e.g. InfluxDB or TimescaleDB)
  // For now just acknowledge
  
  return {};
}
