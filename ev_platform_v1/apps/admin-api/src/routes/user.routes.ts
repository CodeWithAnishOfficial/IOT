import { Router } from 'express';
import { AdminUserController } from '../controllers/user.controller';

const router = Router();

// Route: GET /users/list
// Description: List all users with pagination
router.get('/list', AdminUserController.getAllUsers);

// Route: POST /users/create
// Description: Create a new user
router.post('/create', AdminUserController.createUser);

// Route: GET /users/details/:id
// Description: Get details of a specific user
router.get('/details/:id', AdminUserController.getUserDetails);

// Route: PUT /users/update/:id
// Description: Update user details
router.put('/update/:id', AdminUserController.updateUser);

// Route: DELETE /users/delete/:id
// Description: Delete a user
router.delete('/delete/:id', AdminUserController.deleteUser);

// Route: PUT /users/status/:id
// Description: Toggle user blocked/active status
router.put('/status/:id', AdminUserController.toggleBlockUser);

export default router;
