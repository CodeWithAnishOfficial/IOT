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
import chargingRoutes from './routes/charging.routes';
import { BillingService } from './services/billing.service';
import { SseService } from './services/sse.service';
import client from 'prom-client';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
import { IncomingMessage } from 'http';
import url from 'url';

dotenv.config();

const logger = new Logger('User-API');
const app = express();
const PORT = process.env.USER_API_PORT ? parseInt(process.env.USER_API_PORT) : 3001;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ev_platform';
const JWT_SECRET = process.env.JWT_SECRET || 'ev-platform-secret-key';

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
app.use('/charging', chargingRoutes);

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

    // Session Started
    await rabbit.consume('session_started', async (msg) => {
        if (msg.userId) {
             SseService.sendToUser(msg.userId, 'session_started', msg);
        }
    });

    // Charging Progress
    await rabbit.consume('charging_progress', async (msg) => {
        if (msg.userId) {
             SseService.sendToUser(msg.userId, 'charging_progress', msg);
        }
    });

    logger.info('Started consuming events');

    // Create HTTP Server
    const httpServer = createServer(app);

    // Setup WebSocket Server
    const wss = new WebSocketServer({ server: httpServer });

    wss.on('connection', (ws, req: IncomingMessage) => {
      const parameters = url.parse(req.url || '', true);
      const token = parameters.query.token as string;

      if (!token) {
        ws.close(1008, 'Token required');
        return;
      }

      try {
        const decoded: any = jwt.verify(token, JWT_SECRET);
        const userId = decoded.email_id; // Assuming email_id is used as ID in token
        
        logger.info(`WebSocket connected for user: ${userId}`);
        SseService.addWsClient(ws, userId);

        // Send initial ping or welcome
        ws.send(JSON.stringify({ event: 'connected', message: 'WebSocket connection established' }));

      } catch (err) {
        logger.error('WebSocket authentication failed', err);
        ws.close(1008, 'Authentication failed');
      }
    });

    httpServer.listen(PORT, () => {
      logger.info(`User API running on port ${PORT} (HTTP + WS)`);
    });

  } catch (error) {
    logger.error('Failed to start User API', error);
    process.exit(1);
  }
};

start();
