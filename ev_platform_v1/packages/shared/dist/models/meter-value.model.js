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
exports.MeterValue = void 0;
const mongoose_1 = __importStar(require("mongoose"));
const MeterValueSchema = new mongoose_1.Schema({
    Voltage: { type: String, default: "0.00" },
    Current: {
        Import: { type: String, default: "0.00" }
    },
    Power: {
        Active: {
            Import: { type: String, default: "0.00" }
        },
        Factor: { type: String, default: "0.00" }
    },
    Energy: {
        Active: {
            Import: {
                Register: { type: String, default: "0" }
            }
        }
    },
    Frequency: { type: String, default: "0" },
    charger_id: { type: String, required: true },
    Timestamp: { type: String, required: true },
    clientIP: { type: String },
    SessionID: { type: Number, required: true },
    connectorId: { type: Number, required: true }
}, { strict: false }); // strict: false allows saving other fields if necessary
exports.MeterValue = mongoose_1.default.model('MeterValue', MeterValueSchema);
//# sourceMappingURL=meter-value.model.js.map