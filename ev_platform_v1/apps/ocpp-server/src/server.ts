import WebSocket, { WebSocketServer } from 'ws';
import { Logger, RedisService } from '@ev-platform-v1/shared';
import { IncomingMessage } from 'http';
import { ConnectionManager } from './core/connection.manager';
import { MessageRouter } from './core/message.router';
import { createServer, Server } from 'https';
import fs from 'fs';
import path from 'path';
import { TLSSocket } from 'tls';
import client from 'prom-client';

export class OCPPServer {
  private port: number;
  private wss: WebSocketServer | null = null;
  private logger: Logger;
  private connectionManager: ConnectionManager;
  private redis: RedisService;
  private httpServer: Server | null = null;

  constructor(port: number) {
    this.port = port;
    this.logger = new Logger('OCPP-Server');
    this.connectionManager = new ConnectionManager();
    this.redis = RedisService.getInstance();
    
    // Prometheus
    const collectDefaultMetrics = client.collectDefaultMetrics;
    collectDefaultMetrics({ register: client.register });

    this.initializeRedisListeners();
  }

  private initializeRedisListeners() {
    this.redis.subscribe('ocpp:commands', (data: any) => {
      const { chargerId, command, payload } = data;
      this.logger.info(`Received remote command ${command} for ${chargerId}`);
      
      const connection = this.connectionManager.getConnection(chargerId);
      if (connection && connection.isAlive) {
        // Send command to charger (OCPP Type 2 Request)
        const requestId = Date.now().toString();
        // [2, UniqueId, Action, Payload]
        connection.send([2, requestId, command, payload]);
      } else {
        this.logger.warn(`Charger ${chargerId} not connected or offline. Cannot send ${command}`);
      }
    });
  }

  public async start(): Promise<void> {
    return new Promise((resolve) => {
      // Basic TLS Security Profile (Profile 2 or 3)
      // Check for certificates
      const certPath = process.env.TLS_CERT_PATH || path.join(__dirname, '../certs/server.cert');
      const keyPath = process.env.TLS_KEY_PATH || path.join(__dirname, '../certs/server.key');
      const caPath = process.env.TLS_CA_PATH || path.join(__dirname, '../certs/ca.cert');

      let serverOptions: any = {};
      
      if (fs.existsSync(certPath) && fs.existsSync(keyPath)) {
        this.logger.info('Starting with TLS support (Security Profile 2/3)');
        serverOptions = {
            cert: fs.readFileSync(certPath),
            key: fs.readFileSync(keyPath),
            // For Profile 3 (Mutual TLS), we need to request client cert and verify against CA
            requestCert: process.env.OCPP_SECURITY_PROFILE === '3',
            rejectUnauthorized: process.env.OCPP_SECURITY_PROFILE === '3',
        };

        if (process.env.OCPP_SECURITY_PROFILE === '3' && fs.existsSync(caPath)) {
             serverOptions.ca = [fs.readFileSync(caPath)];
        }

        this.httpServer = createServer(serverOptions);
        
        // Add Metrics endpoint to HTTPS server
        this.httpServer.on('request', async (req, res) => {
             if (req.url === '/metrics' && req.method === 'GET') {
                 res.setHeader('Content-Type', client.register.contentType);
                 res.end(await client.register.metrics());
                 return;
             }
             if (req.url === '/health' && req.method === 'GET') {
                 res.setHeader('Content-Type', 'application/json');
                 res.end(JSON.stringify({ status: 'UP', service: 'OCPP-Server' }));
                 return;
             }
        });

        this.wss = new WebSocketServer({ server: this.httpServer });
      } else {
        this.logger.warn('Certificates not found. Starting in insecure mode (ws://).');
        this.wss = new WebSocketServer({ port: this.port });
        // NOTE: In WS mode (no http server passed), ws creates one internally but we can't easily attach routes to it unless we create our own http server.
        // For simplicity, let's assume secure mode or we accept no metrics in insecure mode for now, or create a separate http server for metrics.
      }

      if (this.wss) {
        this.wss.on('connection', (ws: WebSocket, req: IncomingMessage) => {
          
          // Verify Client Certificate if Profile 3
          if (process.env.OCPP_SECURITY_PROFILE === '3') {
              const socket = req.socket as TLSSocket;
              if (socket.authorized) {
                   const cert = socket.getPeerCertificate();
                   this.logger.info(`Client authorized: ${cert.subject.CN}`);
              } else {
                   this.logger.error(`Client unauthorized: ${socket.authorizationError}`);
                   ws.close();
                   return;
              }
          }

          // Handle Async Connection
          this.connectionManager.handleConnection(ws, req).then(connection => {
            if (connection) {
              ws.on('message', (message: string) => {
                try {
                  const parsed = JSON.parse(message.toString());
                  MessageRouter.handleMessage(connection, parsed);
                } catch (error) {
                  this.logger.error('Error parsing message', error);
                }
              });
            }
          }).catch(err => {
              this.logger.error('Error handling connection', err);
              ws.close();
          });
        });

        if (this.httpServer) {
            this.httpServer.listen(this.port, () => {
                this.logger.info(`OCPP Server (WSS) started on port ${this.port}`);
                resolve();
            });
        } else {
             this.wss.on('listening', () => {
                this.logger.info(`OCPP Server (WS) started on port ${this.port}`);
                resolve();
            });
        }
      }
    });
  }

  public stop(): void {
    if (this.wss) {
      this.wss.close(() => {
        this.logger.info('OCPP Server stopped');
      });
    }
    if (this.httpServer) {
        this.httpServer.close();
    }
  }
}

