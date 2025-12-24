export interface BaseResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
}

// Renamed to avoid conflict with Mongoose Model
export interface ChargingSessionDTO {
  sessionId: string;
  chargePointId: string;
  connectorId: number;
  status: 'active' | 'completed' | 'error';
  startTime: Date;
  endTime?: Date;
  kwhConsumed: number;
}
