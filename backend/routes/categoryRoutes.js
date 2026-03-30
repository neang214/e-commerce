import express from 'express';
import * as ctrl from '../controllers/categoryController.js';
import auth from '../middleware/auth.js';
import admin from '../middleware/admin.js';

const router = express.Router();

router.get('/', ctrl.getAll);
router.post('/', auth, admin, ctrl.create);
router.delete('/:id', auth, admin, ctrl.remove);

export default router;