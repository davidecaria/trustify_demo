"use strict";
// imports
const express = require("express");
const morgan = require("morgan");
const { generateChallenge, authenticate } = require("./controller");
const authenticationDB = require('./connection');

// init
const app = express();
const port = 3001;
const router = express.Router();

// set up middlewares
app.use('/api', router);
app.use(express.json());
app.use(morgan("dev"));

// Connect to MongoDB
authenticationDB();

/* ROUTES*/
router.get("/authenticate", generateChallenge);

//challenge validation to authenticate user
router.post("/authenticate", authenticate);

//create and register a new passkey
router.post("/register", authenticate);

// start the server
app.listen(port, () => "API server started");