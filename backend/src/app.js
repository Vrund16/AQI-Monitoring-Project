
const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "AQI Monitoring API is running",
    status: "success"
  });
});

app.get("/api/health", (req, res) => {
  res.json({
    status: "success",
    message: "Backend is healthy"
  });
});

module.exports = app;