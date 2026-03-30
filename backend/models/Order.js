import mongoose from "mongoose";

const orderSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  totalPrice: Number,
  status: {
    type: String,
    enum: ['pending', 'paid', 'shipped', 'completed'],
    default: 'pending'
  },
  address: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Address'
  }
}, { timestamps: true });

export default mongoose.model('Order', orderSchema);