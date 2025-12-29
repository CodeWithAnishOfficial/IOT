import WebSocket from 'ws';
import { IncomingMessage } from 'http';
import { Logger, ChargingStation } from '@ev-platform-v1/shared';

export class OCPPConnection {
  public readonly id: string;
  public readonly version: string;
  public readonly ip: string;
  public ws: WebSocket;
  public lastHeartbeat: Date;
  public isAlive: boolean;
  private logger: Logger;

  constructor(id: string, version: string, ip: string, ws: WebSocket) {
    this.id = id;
    this.version = version;
    this.ip = ip;
    this.ws = ws;
    this.lastHeartbeat = new Date();
    this.isAlive = true;
    this.logger = new Logger(`OCPPConnection-${id}`);
  }

  send(message: any[]) {
    if (this.ws.readyState === WebSocket.OPEN) {
      this.logger.info(`[${this.id}] <<`, message);
      this.ws.send(JSON.stringify(message));
    }
  }

  sendError(requestId: string, code: string, description: string, details: any = {}) {
    this.send([4, requestId, code, description, details]);
  }

  sendResponse(requestId: string, payload: any) {
    this.send([3, requestId, payload]);
  }
}

export class ConnectionManager {
  private connections: Map<string, OCPPConnection> = new Map();
  private logger: Logger;

  constructor() {
    this.logger = new Logger('ConnectionManager');
    // Start heartbeat monitor
    setInterval(() => this.monitorConnections(), 30000);
  }

  async handleConnection(ws: WebSocket, req: IncomingMessage): Promise<OCPPConnection | null> {
    // Expected URL format: /Quantum/OCPP/{Version}/{ChargerId}
    const url = req.url || '';
    const parts = url.split('/').filter(p => p.length > 0);
    const ip = req.socket.remoteAddress || 'unknown';

    // Parts: ['Quantum', 'OCPP', '1.6', 'charger123']
    if (parts.length < 4 || parts[0] !== 'Quantum' || parts[1] !== 'OCPP') {
      this.logger.warn(`Invalid URL format from ${ip}: ${url}`);
      ws.close(1002, 'Invalid URL format'); // Protocol Error
      return null;
    }

    const version = parts[2];
    const id = parts[3];

    // Validate version if necessary
    if (!['1.6', '2.0', '2.0.1'].includes(version)) {
      this.logger.warn(`Unsupported protocol version from ${ip}: ${version}`);
      ws.close(1002, 'Unsupported Protocol Version');
      return null;
    }

    // AUTHENTICATION CHECK
    const station = await ChargingStation.findOne({ charger_id: id });
    
    if (!station) {
        this.logger.warn(`Unknown charger ${id} tried to connect from ${ip}`);
        ws.close(4004, 'Unknown Station'); // Custom code or 1002
        return null;
    }

    // Check Authorization Header (Basic Auth)
    const authHeader = req.headers['authorization'];
    if (station.ocpp_password) {
        if (!authHeader) {
            this.logger.warn(`Missing authorization header for ${id}`);
            ws.close(4001, 'Unauthorized');
            return null;
        }

        const [scheme, credentials] = authHeader.split(' ');
        if (scheme !== 'Basic' || !credentials) {
            this.logger.warn(`Invalid auth scheme for ${id}`);
            ws.close(4001, 'Unauthorized');
            return null;
        }

        const decoded = Buffer.from(credentials, 'base64').toString();
        // Format: username:password (OCPP spec says username is chargePointIdentity)
        const [username, password] = decoded.split(':');

        if (username !== id || password !== station.ocpp_password) {
            this.logger.warn(`Invalid credentials for ${id}`);
            ws.close(4001, 'Unauthorized');
            return null;
        }
    }

    const existing = this.connections.get(id);
    if (existing) {
      this.logger.warn(`Duplicate connection for ${id}. Closing old connection.`);
      existing.ws.close();
    }

    const connection = new OCPPConnection(id, version, ip, ws);
    this.connections.set(id, connection);
    
    this.logger.info(`New connection: ${id} (v${version}) from ${ip}`);
    
    // Update IP in DB
    await ChargingStation.updateOne({ charger_id: id }, { $set: { ip_address: ip, status: 'online' } });

    ws.on('close', async () => {
      this.logger.info(`Connection closed: ${id}`);
      this.connections.delete(id);
      await ChargingStation.updateOne({ charger_id: id }, { $set: { status: 'offline' } });
    });

    ws.on('pong', () => {
      connection.isAlive = true;
      connection.lastHeartbeat = new Date();
    });

    return connection;
  }

  getConnection(id: string): OCPPConnection | undefined {
    return this.connections.get(id);
  }

  private monitorConnections() {
    this.connections.forEach((conn) => {
      if (conn.isAlive === false) {
        this.logger.warn(`Terminating inactive connection: ${conn.id}`);
        conn.ws.terminate();
        this.connections.delete(conn.id);
        ChargingStation.updateOne({ charger_id: conn.id }, { $set: { status: 'offline' } }).catch(console.error);
        return;
      }

      conn.isAlive = false;
      conn.ws.ping();
    });
  }
}
