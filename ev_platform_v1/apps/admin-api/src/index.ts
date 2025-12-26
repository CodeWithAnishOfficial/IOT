import { initTracing } from '@ev-platform-v1/shared';
initTracing('admin-api');

import express from 'express';
import cors from 'cors';
import { Logger, Database } from '@ev-platform-v1/shared';
import dotenv from 'dotenv';
import chargingStationRoutes from './routes/charging-station.routes';
import remoteCommandRoutes from './routes/remote-command.routes';
import userRoutes from './routes/user.routes';
import tariffRoutes from './routes/tariff.routes';
import dashboardRoutes from './routes/dashboard.routes';
import supportRoutes from './routes/support.routes';
import sessionRoutes from './routes/session.routes';
import siteRoutes from './routes/site.routes';
import roleRoutes from './routes/role.routes';
import authRoutes from './routes/auth.routes';
import { SeederService } from './services/seeder.service';
import client from 'prom-client';
import path from 'path';

dotenv.config();

const logger = new Logger('Admin-API');
const app = express();
const PORT = process.env.ADMIN_API_PORT ? parseInt(process.env.ADMIN_API_PORT) : 3002;
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ev_platform';

// Prometheus Metrics
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ register: client.register });

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// Routes
app.use('/stations', chargingStationRoutes);
app.use('/sites', siteRoutes);
app.use('/roles', roleRoutes);
app.use('/commands', remoteCommandRoutes);
app.use('/users', userRoutes);
app.use('/tariffs', tariffRoutes);
app.use('/dashboard', dashboardRoutes);
app.use('/support', supportRoutes);
app.use('/sessions', sessionRoutes);
app.use('/auth', authRoutes);

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.get('/health', (req, res) => {
  res.json({ status: 'UP', service: 'Admin-API' });
});

const start = async () => {
  try {
    await Database.getInstance().connect(MONGO_URI);
    
    // Seed initial data
    await SeederService.seed();

    app.listen(PORT, () => {
      logger.info(`Admin API running on port ${PORT}`);
    });
  } catch (error) {
    logger.error('Failed to start Admin API', error);
    process.exit(1);
  }
};

start();

