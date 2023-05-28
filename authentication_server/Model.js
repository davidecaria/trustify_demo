"use strict";

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    walletPublicKey: {
        type: String,
        required: true,
        unique: true,
    },
    //passkeys are stored inside wallet array
    wallet: [{
        relyingPartyId: {
            type: String,
            required: true,
            max: 255,
            unique: true
        },

        relyingPartyName: {
            type: String,
            required: true,
            max: 255,
        },

        username: {
            type: String,
            required: true,
            max: 255,
            unique: true
        },

        passkeyPublicKey: {
            type: String,
            required: true,
            unique: true
        },

        passkeySecretKeyE2E: {
            type: String,
            required: true,
            unique: true
        },

        //signature of passkey made with the wallet private key
        passkeySignature: {
            type: String,
            required: true,
            unique: true
        }
    }]
});

// Define a schema for nonce secure handling during authentication
const usedNonceSchema = new mongoose.Schema({
    walletPublicKey: {
        type: String,
        required: true,
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
});

// Create a model based on the schema
const UsedNonce = mongoose.model('UsedNonce', usedNonceSchema);
const UserSchema = mongoose.model('UserSchema', userSchema);

module.exports = { UsedNonce, UserSchema };
