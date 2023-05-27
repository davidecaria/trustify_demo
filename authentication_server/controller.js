"use strict";
const crypto = require("crypto");
const moment = require('moment');
const { UsedNonce, UserSchema } = require("./Model");



/** - This route is called by the client application to initiate the authentication process:
 *  - Request Body: None 
 *  - Response Body: the challenge (Random Nonce) to solve in order to authenticate
 *    @param walletPublicKey
 *    to temporarily store the output nonce in order to later correctly 
 *    perform authentication validation
*/
const generateChallenge = async (request, response) => {
    try {
        if (!request.query.walletPublicKey || request.query.walletPublicKey.trim() === "") {
            return response.status(400).json({ error: "walletPublicKey is missing" });
        }

        const walletPublicKey = request.query.walletPublicKey.trim();
        const nonce = crypto.randomBytes(16).toString("hex");

        const hash = crypto.createHash("sha256");

        hash.update(nonce);

        const challenge = hash.digest("hex");

        // store nonces to keep track of the one been sent and avoid replay attacks
        await UsedNonce.create({ walletPublicKey: walletPublicKey, nonce: nonce });

        return response.status(200).json({ challenge: challenge });
    } catch (error) {
        return response.status(400).json({ error: error });
    }
};


/** - This route is called by the client application to answer to an asymmetric challenge-response
 *  - Request Body: contains the signed nonce previously received by the server (response), claimant's wallet's public key, plaintext nonce
 *  - Response Body: contains a message expressing if authentication is successful or not
*/
const authenticate = async (request, response) => {
    try {
        if (!request.body.hasOwnProperty("walletPublicKey") || !request.body.hasOwnProperty("response") || !request.body.hasOwnProperty("nonce")) {
            return response.status(400).json({ error: "Parameters are missing" });
        }

        if (!request.body.walletPublicKey || !request.body.response || !request.body.nonce) {
            return response.status(400).json({ error: "Empty Parameters" });
        }

        const { walletPublicKey, response, nonce } = req.body;

        const authenticationMaterial = await UsedNonce.find({ walletPublicKey: walletPublicKey, nonce: nonce });

        //nonce was not issued by server or "belongs" to a different user
        if (!authenticationMaterial) {
            return response.status(401).json({ flag: false, error: "Unauthorized" });
        }

        //check if nonce has not expired
        const currentDate = moment();
        const duration = moment.duration(currentDate.diff(authenticationMaterial.validity));
        const minutesDiff = duration.asMinutes();

        if (minutesDiff > 1) {
            return response.status(400).json({ flag: false, error: "Nonce expired" });
        }

        const passkey = await UserSchema.find({ walletPublicKey: walletPublicKey });

        //check signature
        const verifier = crypto.createVerify('RSA-SHA256');
        verifier.update(nonce);

        const isSignatureValid = verifier.verify(passkey.wallet.passkeyPublicKey, response, 'base64');

        if (!isSignatureValid) {
            return response.status(400).json({ flag: false, error: "Authentication failed" });
        }

        return response.status(400).json({ flag: true, message: "Authentication succeeded" });
    } catch (error) {
        return response.status(400).json({ flag: false, error: error });
    }
};

module.exports = { authenticate, generateChallenge };