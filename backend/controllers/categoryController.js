import Category from '../models/Category.js';

export const getAll = async (req, res, next) => {
  try {
    const data = await Category.find();
    res.json(data);
  } catch (err) {
    next(err);
  }
};

export const create = async (req, res, next) => {
  try {
    const { name } = req.body;
    if (!name) return res.status(400).json({ msg: 'name is required' });

    const item = await Category.create({ name });
    res.status(201).json(item);
  } catch (err) {
    next(err);
  }
};

export const remove = async (req, res, next) => {
  try {
    const item = await Category.findByIdAndDelete(req.params.id);
    if (!item) return res.status(404).json({ msg: 'Category not found' });
    res.json({ msg: 'Deleted' });
  } catch (err) {
    next(err);
  }
};