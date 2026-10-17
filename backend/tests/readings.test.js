const test = require("node:test");
const assert = require("node:assert/strict");
const request = require("supertest");

const app = require("../src/app");

test("GET / returns API status", async () => {
  const response = await request(app).get("/");

  assert.equal(response.status, 200);
  assert.equal(response.body.status, "success");
});

test("GET /api/health returns server status", async () => {
  const response = await request(app).get("/api/health");

  assert.equal(response.status, 200);
  assert.equal(response.body.server, "running");
  assert.ok(["connected", "disconnected"].includes(
    response.body.database
  ));
});

test("Unknown route returns 404", async () => {
  const response = await request(app).get("/unknown-route");

  assert.equal(response.status, 404);
  assert.equal(response.body.status, "error");
});

test("Missing sensor fields return 400", async () => {
  const response = await request(app)
    .post("/api/readings")
    .send({ deviceId: "ESP32-01" });

  assert.equal(response.status, 400);
  assert.equal(response.body.status, "error");
});

test("Negative gas readings return 400", async () => {
  const response = await request(app)
    .post("/api/readings")
    .send({
      deviceId: "ESP32-01",
      co2: 500,
      co: -1,
      no2: 0.02,
      temperature: 28,
      humidity: 60
    });

  assert.equal(response.status, 400);
  assert.match(response.body.message, /negative/i);
});

test("Invalid humidity returns 400", async () => {
  const response = await request(app)
    .post("/api/readings")
    .send({
      deviceId: "ESP32-01",
      co2: 500,
      co: 0.5,
      no2: 0.02,
      temperature: 28,
      humidity: 150
    });

  assert.equal(response.status, 400);
});
