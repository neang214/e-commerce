import express from 'express';
import * as ctrl from '../controllers/productController.js';
import auth from '../middleware/auth.js';
import admin from '../middleware/admin.js';
 
const router = express.Router();
 
// SEARCH must come before /:id to avoid being swallowed as an ID param
router.get('/search', ctrl.search);
 
// GET all
router.get('/', ctrl.getAll);
 
// CREATE product (admin only)
// Image is uploaded separately via POST /api/upload; the returned path
// is sent here as part of the JSON body — no multipart needed.
router.post('/', auth, admin, ctrl.create);
 
// GET single product by ID — must come after /search
router.get('/:id', ctrl.getById);
 
// UPDATE (admin)
router.put('/:id', auth, admin, ctrl.update);
 
// DELETE (admin)
router.delete('/:id', auth, admin, ctrl.remove);
 
export default router;