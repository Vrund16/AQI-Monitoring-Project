const express = require("express");

const {
  createReading,
  getLatestReading,
  getReadings
} = require("../controllers/readingsController");

const router = express.Router();

router.post("/", createReading);
router.get("/latest", getLatestReading);
router.get("/", getReadings);

module.exports = router;
