import express from 'express';
import { pay } from '../controllers/paymentController.js';
import auth from '../middleware/auth.js';

const router = express.Router();

router.post('/', auth, pay);

export default router;