"use strict";

const mongoose = require('mongoose');


/**
 * @description 
 * Define a Schema for the passkey object to be stored inside corresponding user's wallet 
 * @param relyingPartyId - relying party's unique identifier
 * @param relyingPartyName - relying party identification name
 * @param username - user's identifier within relying party's provided service/application
 * @param passkeyPublicKey - passkey's public-key associated to relying party's auhtentication (RSA public-key in pem format, then base64 encoded)
 * @param passkeySecretKeyE2E - passkey's secret-key associated to relying party's authentication (RSA secret-key in pem format, AES-256-CBC encrypted, then base64 encoded)
 * @param passkeySignature - signature computed using wallet's secret-key over passkey's credential option (RSA signature, then base64 encoded)
*/
const passkeySchema = new mongoose.Schema({
    relyingPartyId: {
        type: String,
        required: true,
        max: 255,
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
    },

    passkeyPublicKey: {
        type: String,
        required: true,
    },

    passkeySecretKeyE2E: {
        type: String,
        required: true,
    },

    passkeySignature: {
        type: String,
        required: true,
    }
});

/**
 * @description 
 * Define a schema for user persistent storage and server-side handling of its passkeys and associated material
 * @param walletPublicKey - user's wallet public-key (RSA public-key in pem format, then base64 encoded)
 * @param wallet - JSON array of passkey objects; each passkey is a JSON object with the following elements:
 */
const userSchema = new mongoose.Schema({
    walletPublicKey: {
        type: String,
        required: true,
        unique: true,
    },

    wallet: {
        type: [passkeySchema],
        default: []
    }
});

/**
 * @description 
 * Define a schema for nonce secure handling during authentication
 * @param walletPublicKey - user's wallet public-key used to keep track user's authentication requests 
 * @param relyingPartyId - relying party's unique identifier to keep track of the service for which authentication was requested
 * @param challenge - random nonce to be signed by user in order to prove authentication
 * @param validity - timestamp of the moment in which the challenge was created in order to expire it after a reasonable time period
*/
const usedNonceSchema = new mongoose.Schema({
    walletPublicKey: {
        type: String,
        required: true,
    },

    relyingPartyId: {
        type: String,
        required: true,
        max: 255,
    },

    challenge: {
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
const User = mongoose.model('User', userSchema);

module.exports = { UsedNonce, User };
