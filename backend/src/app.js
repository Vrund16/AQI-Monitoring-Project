const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");

const readingsRoutes = require("./routes/readings");
const errorHandler = require("./middleware/errorHandler");

const app = express();

app.use(cors());
app.use(express.json({ limit: "20kb" }));

app.get("/", (req, res) => {
  res.status(200).json({
    status: "success",
    message: "AQI Monitoring API is running."
  });
});

app.get("/api/health", (req, res) => {
  res.status(200).json({
    status: "success",
    server: "running",
    database:
      mongoose.connection.readyState === 1
        ? "connected"
        : "disconnected"
  });
});

app.use("/api/readings", readingsRoutes);

app.use((req, res) => {
  res.status(404).json({
    status: "error",
    message: "Endpoint not found."
  });
});

app.use(errorHandler);

module.exports = app;
