"use strict";

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        max: 255,
        unique: true
    },
});

// Define a schema for the nonce
const usedNonceSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        unique: true
    },

    nonce: {
        type: String,
        required: true,
        unique: true,
    },

    validity: {
        type: Date,
        default: Date.now(),
    },

    used: {
        type: Boolean,
        default: false,
    }
});

// Create a model based on the schema
const UsedNonce = mongoose.model('UsedNonce', usedNonceSchema);

module.exports = { UsedNonce };