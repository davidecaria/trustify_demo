/* Data Access Object (DAO) module for accessing Q&A */
/* Initial version taken from exercise 4 (week 03) */

const mongoose = require('mongoose');

// Connect to the MongoDB database
mongoose.connect('mongodb://localhost/authenticationDB', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Define a schema for the nonce
const nonceSchema = new mongoose.Schema({
  value: {
    type: String,
    required: true,
    unique: true,
  },
});

// Create a model based on the schema
const Nonce = mongoose.model('Nonce', nonceSchema);