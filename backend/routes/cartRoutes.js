import express from 'express';
import { addToCart, getCart, updateCartItem, removeFromCart } from '../controllers/cartController.js';
import auth from '../middleware/auth.js';

const router = express.Router();

router.get('/', auth, getCart);
router.post('/add', auth, addToCart);
router.put('/:itemId', auth, updateCartItem);    // Set exact quantity
router.delete('/:itemId', auth, removeFromCart);

export default router;