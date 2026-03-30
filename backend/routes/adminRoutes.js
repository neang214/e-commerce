import express from 'express';
import { getStats, getAllUsers } from '../controllers/adminController.js';
import auth  from '../middleware/auth.js';
import admin from '../middleware/admin.js';

const router = express.Router();

router.get('/stats', auth, admin, getStats);
router.get('/users', auth, admin, getAllUsers);

export default router;
