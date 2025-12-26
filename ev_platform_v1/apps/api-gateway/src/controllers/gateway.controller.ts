import { Request, Response } from 'express';
import { Logger } from '@ev-platform-v1/shared';
import client from 'prom-client';

const logger = new Logger('GatewayController');

export class GatewayController {
  
  static healthCheck(req: Request, res: Response) {
    res.status(200).json({ status: 'UP', service: 'API-Gateway' });
  }

  static async getMetrics(req: Request, res: Response) {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
  }
}
