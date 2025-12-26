import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { Logger } from '@ev-platform-v1/shared';
import { createProxyMiddleware } from 'http-proxy-middleware';
import client from 'prom-client';
import { limiter } from './middlewares/rateLimit.middleware';
import gatewayRoutes from './routes/gateway.routes';

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
    this.app.use(limiter);
    
    // Logging middleware
    this.app.use((req, res, next) => {
        this.logger.info(`${req.method} ${req.url}`);
        next();
    });
  }

  private initializeRoutes() {
    // Gateway Routes
    this.app.use('/', gatewayRoutes);

    // Proxy to User API
    const userApiUrl = process.env.USER_API_URL || 'http://127.0.0.1:3001';
    
    const userServices = [
        '/auth', '/wallet', '/profile', '/search', 
        '/reservations', '/events', '/vehicles', '/support'
    ];

    userServices.forEach(service => {
        this.app.use(service, createProxyMiddleware({ 
            target: userApiUrl,
            changeOrigin: true,
            onError: (err, req, res) => {
                this.logger.error(`Proxy Error on ${service}`, err);
                res.status(502).json({ error: true, message: 'Bad Gateway' });
            }
        }));
    });

    // Proxy to Admin API
    const adminApiUrl = process.env.ADMIN_API_URL || 'http://127.0.0.1:3002';
    
    // Explicitly proxy admin services if accessed without /admin prefix
    const adminServices = [
      '/stations', '/sites', '/roles', '/commands', '/sessions', '/tariffs', '/dashboard'
    ];

    adminServices.forEach(service => {
      this.app.use(service, createProxyMiddleware({
        target: adminApiUrl,
        changeOrigin: true,
        onError: (err, req, res) => {
          this.logger.error(`Proxy Error on ${service}`, err);
          res.status(502).json({ error: true, message: 'Bad Gateway' });
        }
      }));
    });

    // We map /admin/* to /* on the admin-api
    this.app.use('/admin', createProxyMiddleware({ 
      target: adminApiUrl,
      changeOrigin: true,
      pathRewrite: {
        '^/admin': '', 
      },
      onError: (err, req, res) => {
          this.logger.error(`Proxy Error on /admin`, err);
          res.status(502).json({ error: true, message: 'Bad Gateway' });
      }
    }));
  }

  public start() {
    this.app.listen(this.port, () => {
      this.logger.info(`API Gateway running on port ${this.port}`);
    });
  }
}


