"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validate = void 0;
const zod_1 = require("zod");
const validate = (schema) => (req, res, next) => {
    try {
        schema.parse({
            body: req.body,
            query: req.query,
            params: req.params,
        });
        next();
    }
    catch (error) {
        if (error instanceof zod_1.ZodError) {
            return res.status(400).json({
                error: true,
                message: 'Validation failed',
                details: error.errors.map(e => ({ path: e.path, message: e.message }))
            });
        }
        return res.status(500).json({ error: true, message: 'Internal Server Error' });
    }
};
exports.validate = validate;
//# sourceMappingURL=validate.middleware.js.map