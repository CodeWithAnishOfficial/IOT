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
exports.ChargingSession = void 0;
const mongoose_1 = __importStar(require("mongoose"));
const ChargingSessionSchema = new mongoose_1.Schema({
    charger_id: { type: String, required: true },
    connector_id: { type: Number, required: true },
    connector_type: { type: Number, default: 1 },
    session_id: { type: Number, required: true, unique: true },
    transaction_id: { type: Number },
    start_time: { type: Date, default: Date.now },
    stop_time: { type: Date },
    start_meter_value: { type: Number, default: 0 },
    current_meter_value: { type: Number, default: 0 },
    meter_stop: { type: Number },
    unit_consumed: { type: Number, default: 0 },
    price: { type: Number, default: 0 },
    unit_price: { type: Number, default: 0 },
    error_code: { type: String, default: 'NoError' },
    vendor_error_code: { type: String, default: 'NoVendorError' },
    location: { type: String },
    user_id: { type: mongoose_1.Schema.Types.Mixed, required: true }, // Number or String
    email_id: { type: String },
    created_date: { type: Date, default: Date.now },
    modified_date: { type: Date, default: Date.now },
    status: { type: Boolean, default: true },
    charger_status: { type: String, default: 'Preparing' },
    amount_to_charge: { type: Number },
    consumed_amount: { type: Number, default: 0 },
    remaining_amount: { type: Number },
    // Fees (Strings as per example "0.00")
    EB_fee: { type: String, default: "0.00" },
    association_commission: { type: String, default: "0.00" },
    client_commission: { type: String, default: "0.00" },
    convenience_fee: { type: String, default: "0.00" },
    gst_amount: { type: String, default: "0.00" },
    gst_percentage: { type: String, default: "18" },
    parking_fee: { type: String, default: "0.00" },
    processing_fee: { type: String, default: "0.00" },
    reseller_commission: { type: String, default: "0.00" },
    service_fee: { type: String, default: "0.00" },
    station_fee: { type: String, default: "0.00" },
    stopPending: { type: Boolean, default: false },
    wsActive: { type: Boolean, default: true },
    lastWsPing: { type: Date },
    transactionState: { type: String },
    stop_reason: { type: String },
    auth_tag: { type: String }
});
// Middleware to update modified_date
ChargingSessionSchema.pre('save', function () {
    this.modified_date = new Date();
});
exports.ChargingSession = mongoose_1.default.model('ChargingSession', ChargingSessionSchema);
//# sourceMappingURL=charging-session.model.js.map