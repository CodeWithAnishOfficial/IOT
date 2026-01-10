import WebSocket from 'ws';
import { IncomingMessage } from 'http';
export declare class OCPPConnection {
    readonly id: string;
    readonly version: string;
    readonly ip: string;
    ws: WebSocket;
    lastHeartbeat: Date;
    isAlive: boolean;
    private logger;
    constructor(id: string, version: string, ip: string, ws: WebSocket);
    send(message: any[]): void;
    sendError(requestId: string, code: string, description: string, details?: any): void;
    sendResponse(requestId: string, payload: any): void;
}
export declare class ConnectionManager {
    private connections;
    private logger;
    constructor();
    handleConnection(ws: WebSocket, req: IncomingMessage): Promise<OCPPConnection | null>;
    getConnection(id: string): OCPPConnection | undefined;
    private monitorConnections;
}
