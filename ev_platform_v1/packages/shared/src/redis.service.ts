import Redis from 'ioredis';
import { Logger } from './logger';

export class RedisService {
  private static instance: RedisService;
  private pub: Redis;
  private sub: Redis;
  private logger: Logger;

  private constructor() {
    this.logger = new Logger('RedisService');
    const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
    this.pub = new Redis(redisUrl);
    this.sub = new Redis(redisUrl);
  }

  public static getInstance(): RedisService {
    if (!RedisService.instance) {
      RedisService.instance = new RedisService();
    }
    return RedisService.instance;
  }

  public async publish(channel: string, message: any): Promise<void> {
    try {
      await this.pub.publish(channel, JSON.stringify(message));
    } catch (error) {
      this.logger.error(`Error publishing to ${channel}`, error);
    }
  }

  public async subscribe(channel: string, callback: (message: any) => void): Promise<void> {
    try {
      await this.sub.subscribe(channel);
      this.sub.on('message', (ch, msg) => {
        if (ch === channel) {
          callback(JSON.parse(msg));
        }
      });
    } catch (error) {
      this.logger.error(`Error subscribing to ${channel}`, error);
    }
  }

  // Set remote command for OCPP server to pick up
  public async sendCommand(chargerId: string, command: string, payload: any): Promise<void> {
    const channel = `ocpp:command:${chargerId}`;
    await this.publish('ocpp:commands', { chargerId, command, payload });
  }

  public async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    try {
      const stringValue = JSON.stringify(value);
      if (ttlSeconds) {
        await this.pub.set(key, stringValue, 'EX', ttlSeconds);
      } else {
        await this.pub.set(key, stringValue);
      }
    } catch (error) {
      this.logger.error(`Error setting key ${key}`, error);
    }
  }

  public async get(key: string): Promise<any | null> {
    try {
      const value = await this.pub.get(key);
      if (value) {
        return JSON.parse(value);
      }
      return null;
    } catch (error) {
      this.logger.error(`Error getting key ${key}`, error);
      return null;
    }
  }

  public async del(key: string): Promise<void> {
    try {
      await this.pub.del(key);
    } catch (error) {
      this.logger.error(`Error deleting key ${key}`, error);
    }
  }
}
