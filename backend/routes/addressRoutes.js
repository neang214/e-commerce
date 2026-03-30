import express from 'express';
import * as ctrl from '../controllers/addressController.js';
import auth from '../middleware/auth.js';

const router = express.Router();

router.post('/', auth, ctrl.create);
router.get('/', auth, ctrl.getMy);

export default router;