import mongoose, { Connection } from 'mongoose';
import { Logger } from './logger';

export class Database {
  private static instance: Database;
  private connection: Connection | null = null;
  private logger: Logger;

  private constructor() {
    this.logger = new Logger('Database');
  }

  public static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database();
    }
    return Database.instance;
  }

  public async connect(uri: string): Promise<Connection> {
    if (this.connection) {
      return this.connection;
    }

    try {
      this.logger.info('Connecting to MongoDB...');
      const result = await mongoose.connect(uri);
      this.connection = result.connection;
      this.logger.info('Connected to MongoDB successfully');
      return this.connection;
    } catch (error) {
      this.logger.error('Error connecting to MongoDB', error);
      throw error;
    }
  }

  public async disconnect(): Promise<void> {
    if (this.connection) {
      await mongoose.disconnect();
      this.connection = null;
      this.logger.info('Disconnected from MongoDB');
    }
  }

  public getConnection(): Connection | null {
    return this.connection;
  }
}
