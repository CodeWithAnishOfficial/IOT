import * as amqp from 'amqplib';
import { Logger } from './logger';

export class RabbitMQService {
  private static instance: RabbitMQService;
  private connection: any = null;
  private channel: any = null;
  private logger: Logger;
  private url: string;

  private constructor() {
    this.logger = new Logger('RabbitMQService');
    this.url = process.env.RABBITMQ_URL || 'amqp://user:password@localhost:5672';
  }

  public static getInstance(): RabbitMQService {
    if (!RabbitMQService.instance) {
      RabbitMQService.instance = new RabbitMQService();
    }
    return RabbitMQService.instance;
  }

  public async connect(): Promise<void> {
    if (this.connection) return;

    try {
      this.logger.info(`Connecting to RabbitMQ at ${this.url}`);
      this.connection = await amqp.connect(this.url);
      this.channel = await this.connection.createChannel();
      
      this.connection.on('error', (err: any) => {
        this.logger.error('RabbitMQ connection error', err);
        this.connection = null;
        this.channel = null;
      });

      this.connection.on('close', () => {
        this.logger.warn('RabbitMQ connection closed');
        this.connection = null;
        this.channel = null;
      });

      this.logger.info('Connected to RabbitMQ');
    } catch (error) {
      this.logger.error('Failed to connect to RabbitMQ', error);
      throw error;
    }
  }

  public async assertQueue(queue: string): Promise<void> {
    if (!this.channel) await this.connect();
    if (this.channel) {
        await this.channel.assertQueue(queue, { durable: true });
    }
  }

  public async publish(queue: string, message: any): Promise<boolean> {
    try {
      if (!this.channel) await this.connect();
      
      if (!this.channel) {
          throw new Error('Channel not available');
      }

      await this.assertQueue(queue);
      
      const buffer = Buffer.from(JSON.stringify(message));
      return this.channel.sendToQueue(queue, buffer, { persistent: true });
    } catch (error) {
      this.logger.error(`Error publishing to queue ${queue}`, error);
      return false;
    }
  }

  public async consume(queue: string, callback: (msg: any) => Promise<void>): Promise<void> {
    try {
        if (!this.channel) await this.connect();

        if (!this.channel) {
            throw new Error('Channel not available');
        }

        await this.assertQueue(queue);

        this.channel.consume(queue, async (msg: any) => {
            if (msg) {
                try {
                    const content = JSON.parse(msg.content.toString());
                    await callback(content);
                    this.channel?.ack(msg);
                } catch (error) {
                    this.logger.error(`Error processing message from ${queue}`, error);
                    this.channel?.nack(msg, false, false); 
                }
            }
        });
    } catch (error) {
        this.logger.error(`Error consuming from ${queue}`, error);
    }
  }
}
