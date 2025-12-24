import request from 'supertest';
import express from 'express';
import { TariffService } from '../src/services/tariff.service';

describe('Tariff Service', () => {
    it('should calculate flat rate cost correctly', async () => {
        // Mock DB call
        const mockFindOne = jest.spyOn(require('@ev-platform-v1/shared').ChargingStation, 'findOne');
        const mockTariffFind = jest.spyOn(require('@ev-platform-v1/shared').Tariff, 'findById');

        mockFindOne.mockResolvedValue({ tariff_id: '123' });
        mockTariffFind.mockResolvedValue({ 
            type: 'FLAT', 
            price_per_kwh: 10 
        });

        const cost = await TariffService.calculateCost(10, 60, new Date(), 'charger1');
        expect(cost).toBe(100); // 10 kWh * 10
    });
});
