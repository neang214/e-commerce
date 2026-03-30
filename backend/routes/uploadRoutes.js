import express from 'express';
import upload from '../middleware/upload.js';
import auth from '../middleware/auth.js';

const router = express.Router();

router.post('/', auth, upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ msg: 'No file uploaded' });
    }

    res.json({
        path: req.file.path.replace(/\\/g, '/') // fix Windows path
    });
});

export default router;