"use strict";
const crypto = require("crypto");
const moment = require('moment');
const { UsedNonce, User } = require("./Model");

let challengeCache = [];

/** - This route is called to register a new passkey inside user's wallet
 * @param {walletPublicKey relyingPartyId relyingPartyName username passkeyPublicKey passkeySecretKeyE2E passkeySignature} request 
 * @param {} response 
 * @returns confirmation/rejection message
 */
const register = async (request, response) => {
    try {
        if (!request.body.hasOwnProperty("walletPublicKey") || !request.body.hasOwnProperty("relyingPartyId")
            || !request.body.hasOwnProperty("relyingPartyName") || !request.body.hasOwnProperty("username")
            || !request.body.hasOwnProperty("passkeyPublicKey") || !request.body.hasOwnProperty("passkeySecretKeyE2E")
            || !request.body.hasOwnProperty("passkeySignature")) {
            return response.status(400).json({ flag: false, error: "Missing parameters" });
        }

        if (!request.body.walletPublicKey || !request.body.relyingPartyId
            || !request.body.relyingPartyName || !request.body.username
            || !request.body.passkeyPublicKey || !request.body.passkeySecretKeyE2E || !request.body.passkeySignature) {
            return response.status(400).json({ flag: false, error: "Empty parameters" });
        }

        const { walletPublicKey, relyingPartyId, relyingPartyName, username, passkeyPublicKey, passkeySecretKeyE2E, passkeySignature } = request.body;

        const user = await User.findOne({ walletPublicKey: walletPublicKey });
        console.log(user);

        //storing new passkey inside server-side wallet
        user.wallet.push({
            relyingPartyId: relyingPartyId,
            relyingPartyName: relyingPartyName,
            username: username,
            passkeyPublicKey: passkeyPublicKey,
            passkeySecretKeyE2E: passkeySecretKeyE2E,
            passkeySignature: passkeySignature
        });

        await user.save();

        return response.status(200).json({ flag: true, message: "New passkey registered successfully" });

    } catch (error) {
        console.log(error);
        return response.status(400).json({ flag: false, error: error });
    }
};


/** - This route is called by the client application to initiate the authentication process:
 *  - Request Body: None 
 *  - Response Body: the challenge (Random Nonce) to solve in order to authenticate
 *    @param walletPublicKey, relyingPartyId
 *    to temporarily store the output challenge in order to later correctly 
 *    perform authentication validation
*/
const generateChallenge = async (request, response) => {
    try {
        if (!request.query.relyingPartyId || !request.query.walletPublicKey || request.query.walletPublicKey.trim() === "") {
            return response.status(400).json({ flag: false, error: "Missing parameters" });
        }

        const relyingPartyId = request.query.relyingPartyId;
        const walletPublicKey = request.query.walletPublicKey.trim();
        const nonce = crypto.randomBytes(16).toString("hex");

        const hash = crypto.createHash("sha256");

        hash.update(nonce);

        const challenge = hash.digest("hex");

        const user = await User.findOne({ walletPublicKey: walletPublicKey });

        if (!user) {
            return response.status(401).json({ error: "User does not exists" });
        }

        const passkey = user.wallet.find(passkey => passkey.relyingPartyId === relyingPartyId);

        if (!passkey) {
            return response.status(401).json({ error: `User does not have a valid passkey for service: ${relyingPartyId}` });
        }

        // store nonces to keep track of the one been sent and avoid replay attacks
        await UsedNonce.create({ walletPublicKey: walletPublicKey, relyingPartyId: relyingPartyId, challenge: challenge });

        //cache the obtained challenge
        challengeCache.push(challenge);

        return response.status(200).json({ flag: true, challenge: challenge });
    } catch (error) {
        console.log(error);
        return response.status(400).json({ flag: false, error: error });
    }
};


/** - This route is called by the client application to answer to an asymmetric challenge-response
 *  - Request Body: contains the signed challenge previously received by the server (signature), claimant's wallet's public key, relying party identifier, plaintext challenge
 *  - Response Body: contains a message expressing if authentication is successful or not
*/
const authenticate = async (request, response) => {
    try {
        if (!request.body.hasOwnProperty("walletPublicKey") || !request.body.hasOwnProperty("signature") || !request.body.hasOwnProperty("challenge") ||
            !request.body.hasOwnProperty("relyingPartyId")) {
            //delete last emitted challenges
            await UsedNonce.deleteMany({$or: challengeCache});
            challengeCache = [];
            return response.status(400).json({ error: "Parameters are missing" });
        }

        if (!request.body.walletPublicKey || !request.body.signature || !request.body.challenge || !request.body.relyingPartyId) {
            await UsedNonce.deleteMany({$or: challengeCache});
            challengeCache = [];
            return response.status(400).json({ error: "Empty Parameters" });
        }

        const { walletPublicKey, signature, challenge, relyingPartyId } = request.body;

        const user = await User.findOne({ walletPublicKey: walletPublicKey });

        if (!user) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(401).json({ error: "User does not exists" });
        }

        const authenticationMaterial = await UsedNonce.findOne({ walletPublicKey: walletPublicKey, relyingPartyId: relyingPartyId, challenge: challenge });

        //challenge was not issued by server or "belongs" to a different user
        if (authenticationMaterial.relyingPartyId !== relyingPartyId) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(401).json({ flag: false, error: "Unauthorized" });
        }

        //check if challenge has not expired
        const currentDate = moment();
        const duration = moment.duration(currentDate.diff(authenticationMaterial.validity));
        const minutesDiff = duration.asMinutes();

        if (minutesDiff > 4) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(401).json({ flag: false, error: "Challenge expired" });
        }

        //check signature
        const verifier = crypto.createVerify('RSA-SHA256');
        verifier.update(challenge);

        //retrieve correct passkey
        const passkey = user.wallet.find(passkey => passkey.relyingPartyId === relyingPartyId);
        //retrieving pem format of passkey public key
        const passkeyPublicKey = atob(passkey.passkeyPublicKey);
        //validate authentication
        const isSignatureValid = verifier.verify(passkeyPublicKey, signature, 'base64');

        if (!isSignatureValid) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(400).json({ flag: false, error: "Authentication failed" });
        }

        //removing the challenge record, in order to allow same user to authenticate to other services
        await authenticationMaterial.deleteOne({ challenge: challenge });

        return response.status(200).json({ flag: true, message: "Authentication succeeded" });
    } catch (error) {
        await authenticationMaterial.deleteOne({ challenge: challenge });
        console.log(error);
        return response.status(400).json({ flag: false, error: error });
    }
};

module.exports = { authenticate, generateChallenge, register };
