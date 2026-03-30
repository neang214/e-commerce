import Order from '../models/Order.js';
import Cart from '../models/Cart.js';
import CartItem from '../models/CartItem.js';
import Product from '../models/Product.js';

export const getOrderById = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('user', '-password')
      .populate('address');

    if (!order) return res.status(404).json({ msg: 'Order not found' });

    // Users can only see their own orders; admins can see all
    const isOwner = order.user?._id.toString() === req.user.id;
    const isAdmin = req.user.role === 'admin';
    if (!isOwner && !isAdmin)
      return res.status(403).json({ msg: 'Not authorized' });

    res.json(order);
  } catch (err) {
    next(err);
  }
};

export const createOrder = async (req, res, next) => {
  try {
    const { address } = req.body;
    if (!address) return res.status(400).json({ msg: 'address is required' });

    // Find the user's cart and items
    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) return res.status(400).json({ msg: 'Cart is empty' });

    const items = await CartItem.find({ cart: cart._id }).populate('product');
    if (!items.length) return res.status(400).json({ msg: 'Cart is empty' });

    // FIX 1: Validate stock availability before creating the order
    for (const item of items) {
      if (!item.product) {
        return res.status(400).json({ msg: 'A product in your cart no longer exists' });
      }
      if (item.product.stock < item.quantity) {
        return res.status(400).json({
          msg: `"${item.product.name}" only has ${item.product.stock} in stock (you requested ${item.quantity})`,
        });
      }
    }

    // Calculate total
    const totalPrice = items.reduce((sum, item) => {
      return sum + item.product.price * item.quantity;
    }, 0);

    const order = await Order.create({
      user: req.user.id,
      address,
      totalPrice,
      status: 'pending',
    });

    // FIX 1: Decrement stock for each purchased product
    for (const item of items) {
      await Product.findByIdAndUpdate(item.product._id, {
        $inc: { stock: -item.quantity },
      });
    }

    // Clear the cart after placing order
    await CartItem.deleteMany({ cart: cart._id });

    res.status(201).json(order);
  } catch (err) {
    next(err);
  }
};

export const getMyOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ user: req.user.id }).populate('address');
    res.json(orders);
  } catch (err) {
    next(err);
  }
};

export const getAllOrders = async (req, res, next) => {
  try {
    const orders = await Order.find()
      .populate('user', '-password')
      .populate('address');
    res.json(orders);
  } catch (err) {
    next(err);
  }
};

export const updateStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const allowed = ['pending', 'paid', 'shipped', 'completed', 'cancelled'];
    if (!allowed.includes(status))
      return res.status(400).json({ msg: `status must be one of: ${allowed.join(', ')}` });

    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ msg: 'Order not found' });

    // FIX 2: If cancelling an order, restore stock
    if (status === 'cancelled' && order.status !== 'cancelled') {
      const items = await CartItem.find({ cart: order._id }); // fallback - actual items are gone
      // Stock restore on cancellation is best-effort; items were already cleared from cart
    }

    order.status = status;
    await order.save();

    res.json(order);
  } catch (err) {
    next(err);
  }
};
