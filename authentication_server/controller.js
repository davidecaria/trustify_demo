"use strict";
const crypto = require("crypto");
const moment = require('moment');
const { UsedNonce, User } = require("./Model");

// array used to store and keep track of last sent challenges
let challengeCache = [];

/**
 * @description
 * This route is called to synchronize the requested passkey inside the wallet from which the synchronization request has been sent;
 * the request is a JSON object containing the following parameters:
 * @param walletPublicKey - associated to new user's wallet (RSA public-key in pem format, then base64 encoded)
 * @param relyingPartyName - relying party identification name
 * @param username - user's identifier within relying party's provided service/application
 * @returns a JSON object containing: flag - boolean value expressing success/failure of operation; message/error - message explaining success/failure reasons; 
 * passkey: passkey object to be stored locally on requesting user's device
 */
const synchronizePasskey = async (request, response) => {
    try {

        if (!request.query.hasOwnProperty("walletPublicKey") || !request.query.hasOwnProperty("relyingPartyName")
            || !request.query.hasOwnProperty("username")) {
            return response.status(400).json({ flag: false, error: "Missing parameters" });
        }

        if (!request.query.walletPublicKey || !request.query.relyingPartyName || !request.query.username) {
            return response.status(400).json({ flag: false, error: "Empty Wallet public-key" });
        }

        const { walletPublicKey, relyingPartyName, username } = request.query;

        const user = await User.findOne({ walletPublicKey: walletPublicKey });

        if (!user) {
            return response.status(401).json({ error: "User does not exists" });
        }

        console.log("User requesting synchronization of passkey: " + user.walletPublicKey + "\n\n");

        //retrieve correct passkey
        const passkey = user.wallet.find(passkey => passkey.relyingPartyName === relyingPartyName && passkey.username === username);

        if (!passkey) {
            return response.status(401).json({ error: `User: ${username} does not have a valid passkey for service: ${relyingPartyName}` });
        }

        console.log("Passkey to be synchronized: " + passkey  + "\n\n");

        return response.status(200).json({ flag: true, message: "Passkey retrieved successfully", passkey: passkey });
    } catch (error) {
        return response.status(400).json({ flag: false, error: error });
    }
};

/** 
 *  @description
 * - This route is called to register a new user inside the application through the public key of its wallet: 
 * this is needed to later store its personal passkeys; the request is a JSON object containing the following parameters:
 * @param WalletPublicKey - associated to new user's wallet (RSA public-key in pem format, then base64 encoded)
 * @returns a JSON object containing: flag - boolean value expressing success/failure of operation; message/error - message explaining success/failure reasons 
 */
const registerUser = async (request, response) => {
    try {

        if (!request.body.hasOwnProperty("walletPublicKey")) {
            return response.status(400).json({ flag: false, error: "Missing Wallet public-key" });
        }

        if (!request.body.walletPublicKey) {
            return response.status(400).json({ flag: false, error: "Empty Wallet public-key" });
        }

        const walletPublicKey = request.body.walletPublicKey;

        //creating a new user with an empty wallet
        const newUser = await User.create({ walletPublicKey: walletPublicKey, wallet: [] });

        console.log("New user record: " + newUser  + "\n\n");

        return response.status(200).json({ flag: true, message: "New user created successfully" });
    } catch (error) {
        return response.status(400).json({ flag: false, error: error });
    }
};



/**
 * @description 
 *  This route is called to register a new passkey inside user's wallet; the request is a JSON object containing the following parameters: 
 * @param walletPublicKey - user's wallet public-key (RSA public-key in pem format, then base64 encoded)
 * @param relyingPartyId - relying party's unique identifier
 * @param relyingPartyName - relying party identification name
 * @param username - user's identifier within relying party's provided service/application
 * @param passkeyPublicKey - passkey's public-key associated to relying party's auhtentication (RSA public-key in pem format, then base64 encoded)
 * @param passkeySecretKeyE2E - passkey's secret-key associated to relying party's authentication (RSA secret-key in pem format, AES-256-CBC encrypted, then base64 encoded)
 * @param passkeySignature - signature computed using wallet's secret-key over passkey's credential option (RSA signature, then base64 encoded)
 * @returns a JSON object containing: flag - boolean value expressing success/failure of operation; message/error - message explaining success/failure reasons
 * 
 */
const registerPasskey = async (request, response) => {
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

        if (!user) {
            return response.status(401).json({ error: "User does not exists" });
        }

        console.log("Retrieved user: " + user  + "\n\n");

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
        return response.status(400).json({ flag: false, error: error });
    }
};


/** 
 * @description 
 * This route is called by the client application to initiate the authentication process within a specific relying party; the request 
 * is a JSON object containing the following parameters:
 * @param walletPublicKey - user's wallet public-key (RSA public-key in pem format, then base64 encoded)
 * @param relyingPartyId - relying party's unique identifier
 * @returns a JSON object containing: flag - boolean value expressing success/failure of operation; challenge - random nonce to be signed by user in order to prove authentication; error - message explaining failure reasons
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

        console.log("User requesting authentication: " + user  + "\n\n");

        const passkey = user.wallet.find(passkey => passkey.relyingPartyId === relyingPartyId);

        if (!passkey) {
            return response.status(401).json({ error: `User does not have a valid passkey for service: ${relyingPartyId}` });
        }

        console.log("Passkey to be used: " + passkey  + "\n\n");

        // store nonces to keep track of the one been sent and avoid replay attacks
        const createdNonce = await UsedNonce.create({ walletPublicKey: walletPublicKey, relyingPartyId: relyingPartyId, challenge: challenge });

        console.log("Server-side authentication record: " + createdNonce);

        //cache the obtained challenge
        challengeCache.push(challenge);

        return response.status(200).json({ flag: true, challenge: challenge });
    } catch (error) {
        return response.status(400).json({ flag: false, error: error });
    }
};


/**
 * @description 
 *  This route is called by the client application to answer to an asymmetric challenge-response; the request is 
 *  a JSON object containing the following parameters: 
 *  @param walletPublicKey - user's wallet public-key (RSA public-key in pem format, then base64 encoded)
 *  @param challenge - random nonce previously received by the user to be signed in order to prove passkey's possession
 *  @param signature - signature computed using passkey's secret-key to be validated by the server
 *  @param relyingPartyId - relying party's unique identifier, in order to authenticate correct user to a specific service
 *  @returns a JSON object containing: flag - boolean value expressing success/failure of operation; error - message explaining failure reasons
*/
const authenticate = async (request, response) => {
    try {
        if (!request.body.hasOwnProperty("walletPublicKey") || !request.body.hasOwnProperty("signature") || !request.body.hasOwnProperty("challenge") ||
            !request.body.hasOwnProperty("relyingPartyId")) {
            //delete last emitted challenges
            await UsedNonce.deleteMany({ $or: challengeCache });
            challengeCache = [];
            return response.status(400).json({ error: "Parameters are missing" });
        }

        if (!request.body.walletPublicKey || !request.body.signature || !request.body.challenge || !request.body.relyingPartyId) {
            await UsedNonce.deleteMany({ $or: challengeCache });
            challengeCache = [];
            return response.status(400).json({ error: "Empty Parameters" });
        }

        const { walletPublicKey, signature, challenge, relyingPartyId } = request.body;

        const user = await User.findOne({ walletPublicKey: walletPublicKey });

        console.log("User to authenticate: " + user  + "\n\n");

        if (!user) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(401).json({ error: "User does not exists" });
        }

        const authenticationMaterial = await UsedNonce.findOne({ walletPublicKey: walletPublicKey, relyingPartyId: relyingPartyId, challenge: challenge });

        console.log("Retrieved server-side authentication record" + authenticationMaterial  + "\n\n");

        //challenge was not issued by server or "belongs" to a different user
        if (authenticationMaterial.relyingPartyId !== relyingPartyId) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(401).json({ flag: false, error: "Unauthorized" });
        }

        //check if challenge has not expired
        const currentDate = moment();
        const secondsDifference = moment.duration(currentDate.diff(authenticationMaterial.validity, 'seconds'));
      
        if (secondsDifference > 180) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(401).json({ flag: false, error: "Challenge expired" });
        }

        //check signature
        const verifier = crypto.createVerify('RSA-SHA256');
        verifier.update(challenge);

        //retrieve correct passkey
        const passkey = user.wallet.find(passkey => passkey.relyingPartyId === relyingPartyId);

        if (!passkey) {
            return response.status(401).json({ error: `User does not have a valid passkey for service: ${relyingPartyId}` });
        }

        console.log("Retrieved passkey: " + passkey  + "\n\n");

        //retrieving pem format of passkey public key
        const passkeyPublicKey = atob(passkey.passkeyPublicKey);
        //validate authentication
        const isSignatureValid = verifier.verify(passkeyPublicKey, signature, 'base64');

        console.log("Signature verification result: " + isSignatureValid  + "\n\n");

        if (!isSignatureValid) {
            await authenticationMaterial.deleteOne({ challenge: challenge });
            return response.status(400).json({ flag: false, error: "Authentication failed" });
        }

        //removing the challenge record, in order to allow same user to authenticate to other services
        await authenticationMaterial.deleteOne({ challenge: challenge });

        return response.status(200).json({ flag: true, message: "Authentication succeeded" });
    } catch (error) {
        console.log(error);
        await authenticationMaterial.deleteOne({ challenge: challenge });
        return response.status(400).json({ flag: false, error: error });
    }
};

module.exports = { authenticate, generateChallenge, registerPasskey, registerUser, synchronizePasskey };
