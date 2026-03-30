import Payment from '../models/Payment.js';
import Order from '../models/Order.js';

export const pay = async (req, res, next) => {
  try {
    const { order, method } = req.body;
    if (!order || !method)
      return res.status(400).json({ msg: 'order and method are required' });

    const existingOrder = await Order.findById(order);
    if (!existingOrder) return res.status(404).json({ msg: 'Order not found' });
    if (existingOrder.status === 'paid')
      return res.status(400).json({ msg: 'Order is already paid' });

    const payment = await Payment.create({ order, method, status: 'completed' });
    await Order.findByIdAndUpdate(order, { status: 'paid' });

    res.json(payment);
  } catch (err) {
    next(err);
  }
};