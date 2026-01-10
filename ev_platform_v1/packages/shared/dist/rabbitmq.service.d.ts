export declare class RabbitMQService {
    private static instance;
    private connection;
    private channel;
    private logger;
    private url;
    private constructor();
    static getInstance(): RabbitMQService;
    connect(retries?: number, delay?: number): Promise<void>;
    assertQueue(queue: string): Promise<void>;
    publish(queue: string, message: any): Promise<boolean>;
    consume(queue: string, callback: (msg: any) => Promise<void>): Promise<void>;
}
