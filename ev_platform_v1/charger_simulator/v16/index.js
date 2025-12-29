const WebSocket = require('ws');

// Configuration
const CHARGER_ID = 'CH001';
const BACKEND_URL = `ws://localhost:9220/Quantum/OCPP/1.6/${CHARGER_ID}`;
// const AUTH_USER = 'CH001';
// const AUTH_PASS = 'your_password'; // Uncomment and set if your charger has a password

console.log(`Connecting to ${BACKEND_URL}...`);

const options = {};
// If auth is needed:
// const credentials = Buffer.from(`${AUTH_USER}:${AUTH_PASS}`).toString('base64');
// options.headers = { 'Authorization': `Basic ${credentials}` };

const ws = new WebSocket(BACKEND_URL, 'ocpp1.6', options);

let messageId = 1;
let heartbeatInterval;
let transactionId = 0;

function getMessageId() {
    return (messageId++).toString();
}

ws.on('open', function open() {
    console.log('Connected to Backend!');

    // 1. BootNotification
    const bootNotification = [
        2,
        getMessageId(),
        "BootNotification",
        {
            "chargePointVendor": "Quantum",
            "chargePointModel": "Simulator-001",
            "chargePointSerialNumber": "SIM001",
            "chargeBoxSerialNumber": "SIM001",
            "firmwareVersion": "1.0.0",
            "iccid": "",
            "imsi": "",
            "meterType": "Simulated",
            "meterSerialNumber": "M001"
        }
    ];

    send(bootNotification);
});

ws.on('message', function incoming(data) {
    const msg = JSON.parse(data);
    const msgType = msg[0];

    // Explicit Logging of Incoming Server Frames
    if (msgType === 2) { // CALL
        console.log(`\n[SERVER REQUEST] >>> ${msg[2]} (ID: ${msg[1]})`);
        console.log(JSON.stringify(msg, null, 2));
    } else if (msgType === 3) { // CALLRESULT
        console.log(`\n[SERVER RESPONSE] >>> To Request ID: ${msg[1]}`);
        console.log(JSON.stringify(msg, null, 2));
    } else if (msgType === 4) { // CALLERROR
         console.log(`\n[SERVER ERROR] >>> To Request ID: ${msg[1]}`);
         console.log(JSON.stringify(msg, null, 2));
    } else {
        console.log(`\n[UNKNOWN FRAME] >>>`);
        console.log(JSON.stringify(msg, null, 2));
    }
    
    // CALLRESULT (Response to our request)
    if (msgType === 3) {
        const requestId = msg[1];
        const payload = msg[2];
        
        // Handle BootNotification Response
        if (payload.status === 'Accepted' && payload.interval) {
            console.log(`BootNotification Accepted. Interval: ${payload.interval}`);
            
            // Start Heartbeat
            startHeartbeat(payload.interval);

            // Send StatusNotification (Available)
            sendStatusNotification(1, 'Available');

            // Send StatusNotification (Connector 2: Faulted)
            sendStatusNotification(2, 'Faulted', 'InternalError');

            // Simulate a transaction flow after 5 seconds
            setTimeout(() => {
                sendAuthorize();
            }, 5000);
        } else if (payload.transactionId) {
            console.log(`Transaction Started! ID: ${payload.transactionId}`);
            transactionId = payload.transactionId;
            sendStatusNotification(1, 'Charging');
            
            // Start Meter Values loop
            setTimeout(() => sendMeterValues(transactionId), 5000);
            
            // Stop Transaction after 10s
            setTimeout(() => sendStopTransaction(transactionId), 10000);
        } else if (payload.idTagInfo && payload.idTagInfo.status === 'Accepted') {
            console.log('Authorized! Starting Transaction...');
            sendStartTransaction();
        }
    }
    
    // CALL (Request from Server)
    else if (msgType === 2) {
        const requestId = msg[1];
        const action = msg[2];
        const payload = msg[3];

        if (action === 'RemoteStartTransaction') {
            console.log('Received Remote Start!');
            // Accept it
            const response = [3, requestId, { status: 'Accepted' }];
            send(response);

            // Start the transaction
            // Note: In real world, we would check idTag, etc.
            startTransactionFlow(payload.idTag);
        } else if (action === 'RemoteStopTransaction') {
             console.log('Received Remote Stop!');
             const response = [3, requestId, { status: 'Accepted' }];
             send(response);
             // Stop the transaction logic would go here if we were tracking it by ID
        } else {
             // Respond with NotSupported or dummy acceptance
             const response = [3, requestId, { status: 'Rejected' }]; // Default reject for unknown
             send(response);
        }
    }
});

ws.on('close', function close(code, reason) {
    console.log(`Disconnected. Code: ${code}, Reason: ${reason}`);
    clearInterval(heartbeatInterval);
});

ws.on('error', function error(err) {
    console.error('WebSocket Error:', err);
});

function send(msg) {
    const msgType = msg[0];
    if (msgType === 2) {
        console.log(`\n[CLIENT REQUEST] <<< ${msg[2]} (ID: ${msg[1]})`);
    } else if (msgType === 3) {
         console.log(`\n[CLIENT RESPONSE] <<< To Request ID: ${msg[1]}`);
    } else {
        console.log(`\n[CLIENT MESSAGE] <<<`);
    }
    console.log(JSON.stringify(msg, null, 2));
    ws.send(JSON.stringify(msg));
}

function startHeartbeat(interval) {
    if (heartbeatInterval) clearInterval(heartbeatInterval);
    console.log(`Heartbeat interval set to ${interval}s`);
    heartbeatInterval = setInterval(() => {
        const heartbeat = [
            2,
            getMessageId(),
            "Heartbeat",
            {}
        ];
        send(heartbeat);
    }, interval * 1000);
}

function sendStatusNotification(connectorId, status, errorCode = "NoError") {
    const statusNotification = [
        2,
        getMessageId(),
        "StatusNotification",
        {
            "connectorId": connectorId,
            "errorCode": errorCode,
            "status": status
        }
    ];
    send(statusNotification);
}

function startTransactionFlow(idTag = 'TAG001') {
    console.log(`Starting Transaction Flow for ${idTag}...`);
    // 1. Authorize first (though remote start implies auth, it's good practice)
    // In OCPP 1.6 RemoteStartTransaction usually skips explicit Authorize if idTag is provided,
    // but we need to eventually send StartTransaction.
    
    // Simulate plugging in
    sendStatusNotification(1, 'Preparing');
    
    // Send StartTransaction
    setTimeout(() => {
        sendStartTransaction(idTag);
    }, 1000);
}

function sendAuthorize(idTag = 'TAG001') {
    console.log('Sending Authorize...');
    send([
        2,
        getMessageId(),
        "Authorize",
        { "idTag": idTag }
    ]);
}

function sendStartTransaction(idTag = 'TAG001') {
    console.log('Sending StartTransaction...');
    send([
        2,
        getMessageId(),
        "StartTransaction",
        {
            "connectorId": 1,
            "idTag": idTag,
            "meterStart": 0,
            "timestamp": new Date().toISOString()
        }
    ]);
}

function sendMeterValues(transId) {
    console.log(`Sending MeterValues for transaction ${transId}...`);
    send([
        2,
        getMessageId(),
        "MeterValues",
        {
            "connectorId": 1,
            "transactionId": transId,
            "meterValue": [
                {
                    "timestamp": new Date().toISOString(),
                    "sampledValue": [
                        { "value": "10", "context": "Sample.Periodic", "format": "Raw", "measurand": "Energy.Active.Import.Register", "unit": "Wh" }
                    ]
                }
            ]
        }
    ]);
}

function sendStopTransaction(transId, idTag = 'TAG001') {
    console.log(`Sending StopTransaction for transaction ${transId}...`);
    send([
        2,
        getMessageId(),
        "StopTransaction",
        {
            "transactionId": transId,
            "idTag": idTag,
            "meterStop": 20,
            "timestamp": new Date().toISOString(),
            "reason": "Local"
        }
    ]);
    sendStatusNotification(1, 'Available');
}

