const mongoose = require("mongoose");

const readingSchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: true,
      trim: true,
      maxlength: 50
    },
    co2: {
      type: Number,
      required: true,
      min: 0
    },
    co: {
      type: Number,
      required: true,
      min: 0
    },
    no2: {
      type: Number,
      required: true,
      min: 0
    },
    temperature: {
      type: Number,
      required: true,
      min: -40,
      max: 80
    },
    humidity: {
      type: Number,
      required: true,
      min: 0,
      max: 100
    }
  },
  {
    timestamps: true,
    versionKey: false
  }
);

readingSchema.index({
  deviceId: 1,
  createdAt: -1
});

module.exports = mongoose.model("Reading", readingSchema);
