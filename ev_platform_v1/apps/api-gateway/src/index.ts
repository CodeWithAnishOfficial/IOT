import { App } from './app';
import { Logger } from '@ev-platform-v1/shared';
import dotenv from 'dotenv';

dotenv.config();

const logger = new Logger('API-Gateway');
const PORT = process.env.GATEWAY_PORT ? parseInt(process.env.GATEWAY_PORT) : 3000;

const app = new App(PORT);

app.start();
