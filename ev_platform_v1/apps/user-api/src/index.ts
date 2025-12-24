import { initTracing } from '@ev-platform-v1/shared';
initTracing('user-api');

import express from 'express';
import cors from 'cors';
import { Logger, Database, RabbitMQService } from '@ev-platform-v1/shared';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes';
import walletRoutes from './routes/wallet.routes';
import searchRoutes from './routes/search.routes';
import profileRoutes from './routes/profile.routes';
import sseRoutes from './routes/sse.routes';
import reservationRoutes from './routes/reservation.routes';
import vehicleRoutes from './routes/vehicle.routes';
import supportRoutes from './routes/support.routes';
import { BillingService } from './services/billing.service';
import { SseService } from './services/sse.service';
import client from 'prom-client';

dotenv.config();

const logger = new Logger('User-API');
const app = express();
const PORT = process.env.USER_API_PORT ? parseInt(process.env.USER_API_PORT) : 3001;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ev_platform';

// Prometheus Metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ register: client.register });

app.use(cors());
app.use(express.json());

// Routes
app.use('/auth', authRoutes);
app.use('/wallet', walletRoutes);
app.use('/search', searchRoutes);
app.use('/profile', profileRoutes);
app.use('/events', sseRoutes);
app.use('/reservations', reservationRoutes);
app.use('/vehicles', vehicleRoutes);
app.use('/support', supportRoutes);

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'User-API' });
});

const start = async () => {
  try {
    await Database.getInstance().connect(MONGO_URI);
    
    // Connect to RabbitMQ and start consumers
    const rabbit = RabbitMQService.getInstance();
    await rabbit.connect();
    
    // CDR Processing
    await rabbit.consume('cdr_events', async (msg) => {
        await BillingService.processCDR(msg);
        // Also notify user about completed session
        if (msg.userId) {
            SseService.sendToUser(msg.userId, 'session_completed', msg);
        }
    });

    // Station Status Updates (assuming queue exists)
    await rabbit.consume('station_status_events', async (msg) => {
        // Broadcast station status to all users looking at map
        SseService.broadcast('station_status', msg);
    });

    logger.info('Started consuming events');

    app.listen(PORT, () => {
      logger.info(`User API running on port ${PORT}`);
    });
  } catch (error) {
    logger.error('Failed to start User API', error);
    process.exit(1);
  }
};

start();

