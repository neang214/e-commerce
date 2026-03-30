import Cart from '../models/Cart.js';
import CartItem from '../models/CartItem.js';

export const addToCart = async (req, res, next) => {
  try {
    const { product, quantity } = req.body;
    if (!product || !quantity || quantity < 1)
      return res.status(400).json({ msg: 'product and a positive quantity are required' });

    let cart = await Cart.findOne({ user: req.user.id });
    if (!cart) cart = await Cart.create({ user: req.user.id });

    const item = await CartItem.findOneAndUpdate(
      { cart: cart._id, product },
      { $inc: { quantity } },
      { upsert: true, new: true }
    );

    res.status(200).json({ msg: 'Added to cart', item });
  } catch (err) {
    next(err);
  }
};

export const getCart = async (req, res, next) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) return res.json([]);

    const items = await CartItem.find({ cart: cart._id }).populate('product');
    res.json(items);
  } catch (err) {
    next(err);
  }
};

export const updateCartItem = async (req, res, next) => {
  try {
    const { quantity } = req.body;
    if (!quantity || quantity < 1)
      return res.status(400).json({ msg: 'quantity must be at least 1' });

    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) return res.status(404).json({ msg: 'Cart not found' });

    const item = await CartItem.findOneAndUpdate(
      { _id: req.params.itemId, cart: cart._id },
      { quantity },
      { new: true }
    ).populate('product');

    if (!item) return res.status(404).json({ msg: 'Item not found in cart' });

    res.json(item);
  } catch (err) {
    next(err);
  }
};

export const removeFromCart = async (req, res, next) => {
  try {
    const cart = await Cart.findOne({ user: req.user.id });
    if (!cart) return res.status(404).json({ msg: 'Cart not found' });

    const item = await CartItem.findOneAndDelete({
      _id: req.params.itemId,
      cart: cart._id,
    });
    if (!item) return res.status(404).json({ msg: 'Item not found in cart' });

    res.json({ msg: 'Item removed' });
  } catch (err) {
    next(err);
  }
};