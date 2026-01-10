"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const user_controller_1 = require("../controllers/user.controller");
const router = (0, express_1.Router)();
// Route: GET /users/list
// Description: List all users with pagination
router.get('/list', user_controller_1.AdminUserController.getAllUsers);
// Route: POST /users/create
// Description: Create a new user
router.post('/create', user_controller_1.AdminUserController.createUser);
// Route: GET /users/details/:id
// Description: Get details of a specific user
router.get('/details/:id', user_controller_1.AdminUserController.getUserDetails);
// Route: PUT /users/update/:id
// Description: Update user details
router.put('/update/:id', user_controller_1.AdminUserController.updateUser);
// Route: DELETE /users/delete/:id
// Description: Delete a user
router.delete('/delete/:id', user_controller_1.AdminUserController.deleteUser);
// Route: PUT /users/status/:id
// Description: Toggle user blocked/active status
router.put('/status/:id', user_controller_1.AdminUserController.toggleBlockUser);
exports.default = router;
//# sourceMappingURL=user.routes.js.map