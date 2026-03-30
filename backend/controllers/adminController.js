import Order   from '../models/Order.js';
import Product from '../models/Product.js';
import User    from '../models/User.js';

export const getStats = async (req, res, next) => {
  try {
    const [totalOrders, totalProducts, totalUsers, revenueResult] =
      await Promise.all([
        Order.countDocuments(),
        Product.countDocuments(),
        User.countDocuments({ role: 'user' }),
        Order.aggregate([
          { $match: { status: { $in: ['paid', 'shipped', 'completed'] } } },
          { $group: { _id: null, total: { $sum: '$totalPrice' } } },
        ]),
      ]);

    const totalRevenue = revenueResult[0]?.total ?? 0;

    res.json({ totalOrders, totalProducts, totalUsers, totalRevenue });
  } catch (err) {
    next(err);
  }
};

export const getAllUsers = async (req, res, next) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (err) {
    next(err);
  }
};
