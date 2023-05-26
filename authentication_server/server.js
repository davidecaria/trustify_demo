"use strict";

// imports
const express = require("express");
const morgan = require("morgan");
const dao = require("./Dao");
const crypto = require("crypto");

// init
const app = express();
const port = 3001;

// set up middlewares
app.use(express.json());
app.use(morgan("dev"));

/* ROUTES*/

/** - This route is called by the client application to initiate the authentication process:
 *  - Request Body: None 
 *  - Response Body: the challenge (Random Nonce) to solve in order to authenticate
 *  - Parameters: username, to be hashed into che random nonce in order to avoid replay attacks
*/
app.get("/api/authenticate", async (request, response) => {
    try {
        if (!request.query.username || request.query.username.trim() === "") {
            return response.status(400).json({ error: "Username is missing" });
        }

        const username = request.query.username.trim();
        const nonce = crypto.randomBytes(16).toString("hex");

        const hash = crypto.createHash("sha256");

        hash.update(username + nonce);

        const challenge = hash.digest("hex");

        return response.status(200).json({ challenge: challenge });
    } catch (error) {
        return response.status(400).json({ error: error });
    }
});


/** - This route is called by the client application to answer to an asymmetric challenge-response
 *  - Request Body: contains the signed nonce (previously received by the server) and claimant's username
 *  - Response Body: contains a message expressing if authentication is successful or not
*/
app.post("/api/authenticate", (request, response) => {
    try {
        if (!request.body.hasOwnProperty("username") || !request.body.hasOwnProperty("challenge")) {
            return response.status(400).json({ error: "Parameters are missing" });
        }

        if (!request.body.username || !request.body.challenge) {
            return response.status(400).json({ error: "Empty Parameters" });
        }

    } catch (error) {
        return response.status(400).json({ error: error });
    }
});

// start the server
app.listen(port, () => "API server started");