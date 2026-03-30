import Product from '../models/Product.js';

export const getById = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id).populate('category');
    if (!product) return res.status(404).json({ msg: 'Product not found' });
    res.json(product);
  } catch (err) {
    next(err);
  }
};

export const getAll = async (req, res, next) => {
  try {
    const products = await Product.find().populate('category');
    res.json(products);
  } catch (err) {
    next(err);
  }
};

export const create = async (req, res, next) => {
  try {
    const { name, price, stock } = req.body;
    if (!name || price == null || stock == null)
      return res.status(400).json({ msg: 'name, price, and stock are required' });

    const product = await Product.create(req.body);
    res.status(201).json(product);
  } catch (err) {
    next(err);
  }
};

export const update = async (req, res, next) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    if (!product) return res.status(404).json({ msg: 'Product not found' });
    res.json(product);
  } catch (err) {
    next(err);
  }
};

export const remove = async (req, res, next) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ msg: 'Product not found' });
    res.json({ msg: 'Deleted' });
  } catch (err) {
    next(err);
  }
};

export const search = async (req, res, next) => {
  try {
    const { keyword, category } = req.query;
    const filter = {};

    if (keyword) filter.name = { $regex: keyword, $options: 'i' };
    if (category) filter.category = category;

    const products = await Product.find(filter).populate('category');
    res.json(products);
  } catch (err) {
    next(err);
  }
};