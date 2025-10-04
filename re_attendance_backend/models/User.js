const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    fullName: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    code: { type: String, required: true, unique: true },
    role: { 
        type: String, 
        required: true,
        enum: ['worker', 'supervisor', 'management', 'admin'] 
    },
    supervisor_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }
});

module.exports = mongoose.model("User", UserSchema);