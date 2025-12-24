import { initTracing } from '@ev-platform-v1/shared';
initTracing('ocpp-server');

import { OCPPServer } from './server';
import { Logger, Database } from '@ev-platform-v1/shared';
import dotenv from 'dotenv';

dotenv.config();

const logger = new Logger('OCPP-Server');
const PORT = process.env.OCPP_PORT ? parseInt(process.env.OCPP_PORT) : 9220;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ev_platform';

const server = new OCPPServer(PORT);

const start = async () => {
  try {
    await Database.getInstance().connect(MONGO_URI);
    await server.start();
  } catch (err) {
    logger.error('Failed to start OCPP Server', err);
    process.exit(1);
  }
};

start();

process.on('SIGTERM', () => {
  logger.info('SIGTERM received. Shutting down...');
  server.stop();
});

