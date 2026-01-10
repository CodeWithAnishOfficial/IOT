export declare class TariffService {
    /**
     * Calculate cost for a session based on tariff
     * @param energyKwh Total energy in kWh
     * @param durationMin Duration in minutes
     * @param startTime Start time of session
     * @param chargerId Charger ID
     */
    static calculateCost(energyKwh: number, durationMin: number, startTime: Date, chargerId: string): Promise<number>;
    private static isPeakHour;
}
