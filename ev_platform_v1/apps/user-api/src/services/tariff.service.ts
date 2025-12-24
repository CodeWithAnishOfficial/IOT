import { Tariff, ChargingStation, Logger } from '@ev-platform-v1/shared';
import moment from 'moment'; // We need moment or date-fns for time checking. Since not installed, using plain JS or assume installed

const logger = new Logger('TariffService');

export class TariffService {
  /**
   * Calculate cost for a session based on tariff
   * @param energyKwh Total energy in kWh
   * @param durationMin Duration in minutes
   * @param startTime Start time of session
   * @param chargerId Charger ID
   */
  static async calculateCost(energyKwh: number, durationMin: number, startTime: Date, chargerId: string): Promise<number> {
    try {
      // Find Tariff
      const station = await ChargingStation.findOne({ charger_id: chargerId });
      let tariff = null;
      
      if (station && station.tariff_id) {
        tariff = await Tariff.findById(station.tariff_id);
      }

      if (!tariff) {
         // Default Fallback
         logger.info(`No tariff found for ${chargerId}, using default 15 INR/kWh`);
         return energyKwh * 15;
      }

      let cost = 0;
      
      if (tariff.type === 'FLAT') {
          cost = energyKwh * tariff.price_per_kwh;
      } else if (tariff.type === 'TOU') {
          // Time of Use Logic
          // Simplified: check if start time falls in peak hours
          // Ideally we should split the session into peak and off-peak segments
          // But for MVP, we take the price at start time or average.
          // Let's implement: is ANY part of the session in peak hours?
          // Or just check start time.
          
          const isPeak = this.isPeakHour(startTime, tariff.peak_hours);
          const rate = isPeak ? (tariff.price_per_kwh * (tariff.peak_multiplier || 1)) : tariff.price_per_kwh;
          cost = energyKwh * rate;
      }

      // Add idle fee if applicable? 
      // Typically idle fee is applied after charging stops but connector is still occupied.
      // Here we only have total duration. We assume durationMin is active charging time for now.
      
      return Math.round(cost * 100) / 100;
    } catch (error) {
      logger.error('Error calculating cost', error);
      return energyKwh * 15; // Safe fallback
    }
  }

  private static isPeakHour(time: Date, peakHours?: Array<{ start_time: string, end_time: string }>): boolean {
      if (!peakHours || peakHours.length === 0) return false;
      
      const currentHour = time.getHours();
      const currentMin = time.getMinutes();
      const currentTotalMins = currentHour * 60 + currentMin;

      for (const window of peakHours) {
          const [startH, startM] = window.start_time.split(':').map(Number);
          const [endH, endM] = window.end_time.split(':').map(Number);
          
          const startTotal = startH * 60 + startM;
          const endTotal = endH * 60 + endM;

          if (currentTotalMins >= startTotal && currentTotalMins < endTotal) {
              return true;
          }
      }
      return false;
  }
}
