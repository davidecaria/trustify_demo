"use strict";
// imports
const express = require("express");
const morgan = require("morgan");
const { generateChallenge, authenticate, registerPasskey, registerUser , synchronizePasskey} = require("./controller");
const cors = require("cors");
const authenticationDB = require('./connection');

// init
const app = express();
const port = 3001;
const router = express.Router();

// set up middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));
app.use(cors());

app.use('/api', router);

// Connect to MongoDB
authenticationDB();

/* ROUTES*/
router.get("/authenticate", generateChallenge);

// challenge validation to authenticate user
router.post("/authenticate", authenticate);

// create and register a new passkey
router.post("/registerpasskey", registerPasskey);

// create and register a new user with associated wallet
router.post("/newuser", registerUser)

router.get("/synchronizepasskey", synchronizePasskey)

// start the server
app.listen(port, () => console.log(`Trustify API server started on port ${port}`));

