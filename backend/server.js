import express from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import 'dotenv/config';

import authRoutes     from './routes/authRoutes.js';
import productRoutes  from './routes/productRoutes.js';
import cartRoutes     from './routes/cartRoutes.js';
import orderRoutes    from './routes/orderRoutes.js';
import paymentRoutes  from './routes/paymentRoutes.js';
import categoryRoutes from './routes/categoryRoutes.js';
import addressRoutes  from './routes/addressRoutes.js';
import adminRoutes    from './routes/adminRoutes.js';
import DBconnection   from './config/DBconnection.js';
import errorHandler   from './middleware/errorHandler.js';
import uploadRoutes   from './routes/uploadRoutes.js';

const app  = express();
const port = process.env.PORT || 5000;

// FIX: Ensure uploads directory exists on startup
const uploadsDir = path.resolve('uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(express.json());
app.use(cors({
  origin: process.env.CLIENT_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Serve uploaded images
app.use('/uploads', express.static('uploads'));

app.use('/api/upload',     uploadRoutes);
app.use('/api/auth',       authRoutes);
app.use('/api/products',   productRoutes);
app.use('/api/cart',       cartRoutes);
app.use('/api/orders',     orderRoutes);
app.use('/api/payments',   paymentRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/address',    addressRoutes);
app.use('/api/admin',      adminRoutes);

// Global error handler (must be last)
app.use(errorHandler);

(async () => {
  await DBconnection();
  app.listen(port, () => {
    console.log('Server running on port: ' + port);
  });
})();
