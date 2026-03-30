import express from 'express';
import * as ctrl from '../controllers/orderController.js';
import auth from '../middleware/auth.js';
import admin from '../middleware/admin.js';

const router = express.Router();

router.post('/', auth, ctrl.createOrder);           // Place an order
router.get('/my', auth, ctrl.getMyOrders);          // User's own orders
router.get('/', auth, admin, ctrl.getAllOrders);    // Admin: all orders
router.get('/:id', auth, ctrl.getOrderById);        // Single order (owner or admin)
router.put('/:id', auth, admin, ctrl.updateStatus); // Admin: update status

export default router;