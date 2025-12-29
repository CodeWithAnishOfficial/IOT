import { initTracing } from '@ev-platform-v1/shared';
initTracing('ocpp-server');

import { OCPPServer } from './server';
import { Logger, Database, RabbitMQService } from '@ev-platform-v1/shared';
import dotenv from 'dotenv';
import path from 'path';

// Load .env explicitly from one level up (since we are in src/)
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const logger = new Logger('OCPP-Server');
logger.info(`Environment loaded. HEARTBEAT_INTERVAL=${process.env.HEARTBEAT_INTERVAL || 'undefined'}`);

const PORT = process.env.OCPP_PORT ? parseInt(process.env.OCPP_PORT) : 9220;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ev_platform';

const server = new OCPPServer(PORT);

const start = async () => {
  try {
    await Database.getInstance().connect(MONGO_URI);
    
    // Connect to RabbitMQ
    const rabbit = RabbitMQService.getInstance();
    await rabbit.connect();
    
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

