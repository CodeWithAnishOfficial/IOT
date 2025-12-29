import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import WebSocket from 'ws';

interface SseClient {
  type: 'sse';
  id: string;
  res: Response;
  userId: string;
}

interface WsClient {
  type: 'ws';
  id: string;
  ws: WebSocket;
  userId: string;
}

type Client = SseClient | WsClient;

export class SseService {
  private static clients: Client[] = [];

  static addSseClient(res: Response, userId: string) {
    const clientId = uuidv4();
    const newClient: SseClient = { type: 'sse', id: clientId, res, userId };
    this.clients.push(newClient);

    res.on('close', () => {
      this.clients = this.clients.filter(c => c.id !== clientId);
    });
    return clientId;
  }

  static addWsClient(ws: WebSocket, userId: string) {
    const clientId = uuidv4();
    const newClient: WsClient = { type: 'ws', id: clientId, ws, userId };
    this.clients.push(newClient);

    ws.on('close', () => {
      this.clients = this.clients.filter(c => c.id !== clientId);
    });
    return clientId;
  }

  static sendToUser(userId: string, event: string, data: any) {
    const userClients = this.clients.filter(c => c.userId === userId);
    
    userClients.forEach(client => {
      if (client.type === 'sse') {
        client.res.write(`event: ${event}\n`);
        client.res.write(`data: ${JSON.stringify(data)}\n\n`);
      } else {
        if (client.ws.readyState === WebSocket.OPEN) {
          client.ws.send(JSON.stringify({ event, data }));
        }
      }
    });
  }

  static broadcast(event: string, data: any) {
    this.clients.forEach(client => {
      if (client.type === 'sse') {
        client.res.write(`event: ${event}\n`);
        client.res.write(`data: ${JSON.stringify(data)}\n\n`);
      } else {
        if (client.ws.readyState === WebSocket.OPEN) {
          client.ws.send(JSON.stringify({ event, data }));
        }
      }
    });
  }
  
  // Backward compatibility
  static addClient(res: Response, userId: string) {
      return this.addSseClient(res, userId);
  }
}
