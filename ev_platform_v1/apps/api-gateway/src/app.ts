import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { Logger } from '@ev-platform-v1/shared';
import { createProxyMiddleware } from 'http-proxy-middleware';
import client from 'prom-client';
import rateLimit from 'express-rate-limit';

export class App {
  public app: Application;
  private port: number;
  private logger: Logger;

  constructor(port: number) {
    this.app = express();
    this.port = port;
    this.logger = new Logger('API-Gateway');

    // Prometheus
    const collectDefaultMetrics = client.collectDefaultMetrics;
    collectDefaultMetrics({ register: client.register });

    this.initializeMiddlewares();
    this.initializeRoutes();
  }

  private initializeMiddlewares() {
    this.app.use(cors());
    this.app.use(helmet());
    
    // Rate Limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // Limit each IP to 100 requests per windowMs
      standardHeaders: true,
      legacyHeaders: false,
    });
    this.app.use(limiter);

    // Remove body parsers for proxy routes if necessary, but here we might need them for some logic.
    // However, proxies usually handle streams. If we use express.json() globally, it might interfere with proxying bodies.
    // For now, let's keep it but be aware. Actually, standard practice is to apply it only to non-proxy routes.
    // But since we are proxying to APIs that expect JSON, it's fine if we parse it? No, if we parse it, we need to restream it.
    // Simplest is to NOT parse globally.
    // this.app.use(express.json()); 
  }

  private initializeRoutes() {
    this.app.get('/health', (req, res) => {
      res.status(200).json({ status: 'UP', service: 'API-Gateway' });
    });

    this.app.get('/metrics', async (req, res) => {
      res.set('Content-Type', client.register.contentType);
      res.end(await client.register.metrics());
    });

    // Proxy to User API
    this.app.use('/auth', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/wallet', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/profile', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/search', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/reservations', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/events', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/vehicles', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    this.app.use('/support', createProxyMiddleware({ 
      target: process.env.USER_API_URL || 'http://localhost:3001',
      changeOrigin: true,
    }));

    // Proxy to Admin API
    this.app.use('/admin', createProxyMiddleware({ 
      target: process.env.ADMIN_API_URL || 'http://localhost:3002',
      changeOrigin: true,
      pathRewrite: {
        '^/admin': '/', 
      }
    }));
  }

  public start() {
    this.app.listen(this.port, () => {
      this.logger.info(`API Gateway running on port ${this.port}`);
    });
  }
}

