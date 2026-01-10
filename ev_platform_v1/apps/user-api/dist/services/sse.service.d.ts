import { Response } from 'express';
import WebSocket from 'ws';
export declare class SseService {
    private static clients;
    static addSseClient(res: Response, userId: string): string;
    static addWsClient(ws: WebSocket, userId: string): string;
    static sendToUser(userId: string, event: string, data: any): void;
    static broadcast(event: string, data: any): void;
    static addClient(res: Response, userId: string): string;
}
