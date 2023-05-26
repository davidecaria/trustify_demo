"use strict";

const mongoose = require('mongoose');

const authenticationDB = async () => {
  try {
    await mongoose.connect('mongodb://127.0.0.1/authenticationDB', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
  }
};

module.exports = authenticationDB;