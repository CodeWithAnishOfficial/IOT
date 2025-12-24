import { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';

interface Client {
  id: string;
  res: Response;
  userId: string;
}

export class SseService {
  private static clients: Client[] = [];

  static addClient(res: Response, userId: string) {
    const clientId = uuidv4();
    const newClient = { id: clientId, res, userId };
    
    this.clients.push(newClient);

    res.on('close', () => {
      this.clients = this.clients.filter(c => c.id !== clientId);
    });

    return clientId;
  }

  static sendToUser(userId: string, event: string, data: any) {
    const userClients = this.clients.filter(c => c.userId === userId);
    
    userClients.forEach(client => {
      client.res.write(`event: ${event}\n`);
      client.res.write(`data: ${JSON.stringify(data)}\n\n`);
    });
  }

  static broadcast(event: string, data: any) {
    this.clients.forEach(client => {
        client.res.write(`event: ${event}\n`);
        client.res.write(`data: ${JSON.stringify(data)}\n\n`);
    });
  }
}
