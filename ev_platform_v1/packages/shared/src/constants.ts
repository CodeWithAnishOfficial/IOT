export const SERVICE_NAMES = {
  OCPP_SERVER: 'ocpp-server',
  API_GATEWAY: 'api-gateway',
  USER_API: 'user-api',
  ADMIN_API: 'admin-api',
  WORKER: 'worker',
} as const;

export const QUEUE_NAMES = {
  NOTIFICATIONS: 'notifications',
  CHARGING_EVENTS: 'charging_events',
} as const;
