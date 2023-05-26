"use strict";
const crypto = require("crypto");
const { UsedNonce } = require("./Model");



/** - This route is called by the client application to initiate the authentication process:
 *  - Request Body: None 
 *  - Response Body: the challenge (Random Nonce) to solve in order to authenticate
 *    @param username
 *    in order to temporarily store the output nonce in order to later correctly 
 *    perform authentication validation
*/
const generateChallenge = async (request, response) => {

    try {
        if (!request.query.username || request.query.username.trim() === "") {
            return response.status(400).json({ error: "Username is missing" });
        }

        const username = request.query.username.trim();
        const nonce = crypto.randomBytes(16).toString("hex");

        const hash = crypto.createHash("sha256");

        hash.update(nonce);

        const challenge = hash.digest("hex");

        // store nonces to keep track of the one been sent and avoid replay attacks
        await UsedNonce.create({ username, nonce });

        return response.status(200).json({ challenge: challenge });
    } catch (error) {
        return response.status(400).json({ error: error });
    }

};


/** - This route is called by the client application to answer to an asymmetric challenge-response
 *  - Request Body: contains the signed nonce (previously received by the server), claimant's username, plaintext nonce
 *  - Response Body: contains a message expressing if authentication is successful or not
*/
const authenticate = async (request, response) => {

    try {
        if (!request.body.hasOwnProperty("username") || !request.body.hasOwnProperty("challenge")) {
            return response.status(400).json({ error: "Parameters are missing" });
        }

        if (!request.body.username || !request.body.challenge) {
            return response.status(400).json({ error: "Empty Parameters" });
        }

        const { username, challenge } = req.body;

         



    } catch (error) {
        return response.status(400).json({ error: error });
    }
};

module.exports = { authenticate, generateChallenge };