"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChargingStation = void 0;
const mongoose_1 = __importStar(require("mongoose"));
const ChargingStationSchema = new mongoose_1.Schema({
    charger_id: { type: String, required: true, unique: true },
    name: { type: String },
    location: {
        lat: { type: Number },
        lng: { type: Number },
        address: { type: String }
    },
    status: { type: String, enum: ['online', 'offline', 'charging', 'faulted'], default: 'offline' },
    max_power_kw: { type: Number, default: 22.0 }, // Default 22kW station
    tariff_id: { type: String }, // Optional tariff reference
    site_id: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Site' }, // Optional site reference
    // Device Details
    vendor: { type: String },
    modelName: { type: String },
    firmware_version: { type: String },
    serial_number: { type: String },
    // Security
    ip_address: { type: String },
    ocpp_username: { type: String },
    ocpp_password: { type: String }, // Should be hashed in prod, but keeping plain for display if requested
    connectors: [{
            connector_id: { type: Number, required: true },
            status: { type: String, default: 'Available' },
            type: { type: String },
            max_power_kw: { type: Number, default: 22.0 }
        }],
    created_at: { type: Date, default: Date.now },
    updated_at: { type: Date, default: Date.now }
});
exports.ChargingStation = mongoose_1.default.model('ChargingStation', ChargingStationSchema);
//# sourceMappingURL=charging-station.model.js.map