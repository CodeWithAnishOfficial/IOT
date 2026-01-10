"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handleAuthorize = handleAuthorize;
const shared_1 = require("@ev-platform-v1/shared");
const logger = new shared_1.Logger('AuthorizeHandler');
async function handleAuthorize(connection, payload) {
    const { idTag } = payload;
    logger.info(`Authorize from ${connection.id} for tag ${idTag}`);
    // Check if user exists with this tag
    // 1. Check if idTag matches an email
    let user = await shared_1.User.findOne({ email_id: idTag });
    // 2. If not, check if matches rfid_tag
    if (!user) {
        user = await shared_1.User.findOne({ rfid_tag: idTag });
    }
    if (!user) {
        logger.warn(`Authorization failed for tag ${idTag}: User not found`);
        return {
            idTagInfo: {
                status: 'Invalid',
                parentIdTag: null
            }
        };
    }
    if (user.status === false) {
        logger.warn(`Authorization failed for tag ${idTag}: User blocked`);
        return {
            idTagInfo: {
                status: 'Blocked',
                parentIdTag: null
            }
        };
    }
    // Optional: Check Balance
    if (user.wallet_bal < 10) { // Minimum 10 balance
        return {
            idTagInfo: {
                status: 'Blocked', // Or ConcurrentTx? Invalid is better for balance
                parentIdTag: null
            }
        };
    }
    return {
        idTagInfo: {
            status: 'Accepted',
            expiryDate: new Date(Date.now() + 3600 * 1000 * 24 * 30).toISOString(), // 30 days
            parentIdTag: null
        }
    };
}
//# sourceMappingURL=authorize.handler.js.map