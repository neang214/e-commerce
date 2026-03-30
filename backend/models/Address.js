import mongoose from "mongoose";

const addressSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  phone: String,
  addressLine: String,
  city: String
}, { timestamps: true });

export default mongoose.model('Address', addressSchema);