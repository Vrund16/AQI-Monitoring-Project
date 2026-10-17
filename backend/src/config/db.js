const mongoose = require("mongoose");

async function connectDB() {
  const uri = process.env.MONGO_URI;

  if (!uri) {
    console.log("MONGO_URI not set. Running without database.");
    return false;
  }

  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 10000
  });

  console.log("MongoDB connected successfully.");
  return true;
}

module.exports = connectDB;
