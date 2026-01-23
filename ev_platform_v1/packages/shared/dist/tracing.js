"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.initTracing = void 0;
const sdk_node_1 = require("@opentelemetry/sdk-node");
const auto_instrumentations_node_1 = require("@opentelemetry/auto-instrumentations-node");
const exporter_trace_otlp_proto_1 = require("@opentelemetry/exporter-trace-otlp-proto");
const initTracing = (serviceName) => {
    const sdk = new sdk_node_1.NodeSDK({
        serviceName,
        traceExporter: new exporter_trace_otlp_proto_1.OTLPTraceExporter({
            url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://192.168.0.25:4318/v1/traces',
        }),
        instrumentations: [(0, auto_instrumentations_node_1.getNodeAutoInstrumentations)()],
    });
    sdk.start();
    process.on('SIGTERM', () => {
        sdk.shutdown()
            .then(() => console.log('Tracing terminated'))
            .catch((error) => console.log('Error terminating tracing', error))
            .finally(() => process.exit(0));
    });
};
exports.initTracing = initTracing;
//# sourceMappingURL=tracing.js.map