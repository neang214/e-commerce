import Address from '../models/Address.js';

export const create = async (req, res, next) => {
  try {
    const { phone, addressLine, city } = req.body;
    if (!phone || !addressLine || !city)
      return res.status(400).json({ msg: 'phone, addressLine, and city are required' });

    const address = await Address.create({
      ...req.body,
      user: req.user.id,
    });
    res.status(201).json(address);
  } catch (err) {
    next(err);
  }
};

export const getMy = async (req, res, next) => {
  try {
    const data = await Address.find({ user: req.user.id });
    res.json(data);
  } catch (err) {
    next(err);
  }
};