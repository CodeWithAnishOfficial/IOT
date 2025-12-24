export class Logger {
  private serviceName: string;

  constructor(serviceName: string) {
    this.serviceName = serviceName;
  }

  info(message: string, meta?: any) {
    console.log(JSON.stringify({ level: 'info', service: this.serviceName, message, meta, timestamp: new Date() }));
  }

  error(message: string, error?: any) {
    console.error(JSON.stringify({ level: 'error', service: this.serviceName, message, error, timestamp: new Date() }));
  }

  warn(message: string, meta?: any) {
    console.warn(JSON.stringify({ level: 'warn', service: this.serviceName, message, meta, timestamp: new Date() }));
  }
}
