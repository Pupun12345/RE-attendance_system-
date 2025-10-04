const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/User');

const router = express.Router();

// CREATE USER (Admin)
router.post('/', async (req, res) => {
    try {
        const { fullName, email, password, code, role, supervisor_id } = req.body;

        // Check if user or code already exists
        const existingUser = await User.findOne({ $or: [{ email }, { code }] });
        if (existingUser) {
            return res.status(400).json({ message: "User with this email or code already exists" });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new User({ 
            fullName, 
            email, 
            password: hashedPassword, 
            code,
            role,
            supervisor_id: role === 'worker' ? supervisor_id : null 
        });

        await newUser.save();
        res.status(201).json({ message: "User created successfully", user: newUser });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET ALL USERS (Admin)
router.get('/', async (req, res) => {
    try {
        const users = await User.find().select('-password'); // Exclude password from result
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET USER BY ID (Admin)
router.get('/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id).select('-password');
        if (!user) return res.status(404).json({ message: "User not found" });
        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// UPDATE USER (Admin)
router.put('/:id', async (req, res) => {
    try {
        const { fullName, email, code, role, supervisor_id } = req.body;

        const updatedData = {
            fullName,
            email,
            code,
            role,
            supervisor_id: role === 'worker' ? supervisor_id : null
        };

        const updatedUser = await User.findByIdAndUpdate(req.params.id, updatedData, { new: true }).select('-password');
        if (!updatedUser) return res.status(404).json({ message: "User not found" });

        res.json({ message: "User updated successfully", user: updatedUser });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// DELETE USER (Admin)
router.delete('/:id', async (req, res) => {
    try {
        const deletedUser = await User.findByIdAndDelete(req.params.id);
        if (!deletedUser) return res.status(404).json({ message: "User not found" });

        res.json({ message: "User deleted successfully" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;