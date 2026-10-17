const mongoose = require("mongoose");
const Reading = require("../models/Reading");

const requiredFields = [
  "deviceId",
  "co2",
  "co",
  "no2",
  "temperature",
  "humidity"
];

function validateReading(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return "Request body must be a JSON object.";
  }

  for (const field of requiredFields) {
    if (
      body[field] === undefined ||
      body[field] === null ||
      body[field] === ""
    ) {
      return `Missing required field: ${field}`;
    }
  }

  if (
    typeof body.deviceId !== "string" ||
    body.deviceId.trim().length === 0 ||
    body.deviceId.trim().length > 50
  ) {
    return "deviceId must be a non-empty string of at most 50 characters.";
  }

  for (const field of [
    "co2",
    "co",
    "no2",
    "temperature",
    "humidity"
  ]) {
    if (
      typeof body[field] !== "number" ||
      !Number.isFinite(body[field])
    ) {
      return `${field} must be a valid number.`;
    }
  }

  if (body.co2 < 0 || body.co < 0 || body.no2 < 0) {
    return "Gas readings cannot be negative.";
  }

  if (body.temperature < -40 || body.temperature > 80) {
    return "Temperature must be between -40 and 80.";
  }

  if (body.humidity < 0 || body.humidity > 100) {
    return "Humidity must be between 0 and 100.";
  }

  return null;
}

function databaseUnavailable(res) {
  return res.status(503).json({
    status: "error",
    message: "Database is not connected."
  });
}

async function createReading(req, res, next) {
  try {
    const validationError = validateReading(req.body);

    if (validationError) {
      return res.status(400).json({
        status: "error",
        message: validationError
      });
    }

    if (mongoose.connection.readyState !== 1) {
      return databaseUnavailable(res);
    }

    const reading = await Reading.create({
      ...req.body,
      deviceId: req.body.deviceId.trim()
    });

    return res.status(201).json({
      status: "success",
      message: "Sensor reading saved.",
      data: reading
    });
  } catch (error) {
    next(error);
  }
}

async function getLatestReading(req, res, next) {
  try {
    if (mongoose.connection.readyState !== 1) {
      return databaseUnavailable(res);
    }

    const reading = await Reading.findOne()
      .sort({ createdAt: -1 })
      .lean();

    if (!reading) {
      return res.status(404).json({
        status: "error",
        message: "No readings found."
      });
    }

    return res.json({
      status: "success",
      data: reading
    });
  } catch (error) {
    next(error);
  }
}

async function getReadings(req, res, next) {
  try {
    if (mongoose.connection.readyState !== 1) {
      return databaseUnavailable(res);
    }

    const limit = Number(req.query.limit ?? 20);

    if (
      !Number.isInteger(limit) ||
      limit < 1 ||
      limit > 100
    ) {
      return res.status(400).json({
        status: "error",
        message: "limit must be an integer between 1 and 100."
      });
    }

    const readings = await Reading.find()
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();

    return res.json({
      status: "success",
      count: readings.length,
      data: readings
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createReading,
  getLatestReading,
  getReadings
};
