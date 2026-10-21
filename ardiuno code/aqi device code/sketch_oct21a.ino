// ============================================================
//  NODE 4 — AIR QUALITY NODE
//  ESP32 NodeMCU-32S
//  CO  MEMS   → ADS1115 A0  (SDA=21, SCL=22)
//  NO2 MEMS   → ADS1115 A1  (SDA=21, SCL=22)
//  MH-Z19C    → UART RX=16, TX=17
//  DHT22      → GPIO26
//  Backend    → https://aqi-monitoring-project.onrender.com
// ============================================================

#include <Wire.h>
#include <Adafruit_ADS1X15.h>
#include <DHT.h>
#include <HardwareSerial.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// ============================================================
//  ▼▼▼  FILL THESE IN  ▼▼▼
// ============================================================
#define WIFI_SSID        "STUDENT"
#define WIFI_PASSWORD    ""
#define DEVICE_ID        "ESP32_002"
// ============================================================

#define SERVER_URL       "https://aqi-monitoring-project.onrender.com/api/readings"

// ── PINS ─────────────────────────────────────────────────────
#define DHT_PIN          26
#define DHT_TYPE         DHT22
#define CH_CO            0
#define CH_NO2           1
#define CO2_RX_PIN       16
#define CO2_TX_PIN       17
#define CO2_BAUD         9600
#define READ_INTERVAL_MS 10000UL

// ── CALIBRATION ──────────────────────────────────────────────
#define CO_V_ZERO        0.4f
#define CO_SENS_INV      100.0f
#define NO2_V_ZERO       0.4f
#define NO2_SENS_INV     10.0f

// ── THRESHOLDS ───────────────────────────────────────────────
#define THR_CO           35.0f
#define THR_NO2          1.0f
#define THR_CO2          1000.0f
#define THR_TEMP         45.0f
#define THR_RH           90.0f

// ── MH-Z19C command ──────────────────────────────────────────
static const uint8_t CO2_CMD[9] = {
    0xFF,0x01,0x86,0x00,0x00,0x00,0x00,0x00,0x79
};

// ── GLOBALS ──────────────────────────────────────────────────
Adafruit_ADS1115 ads;
DHT              dht(DHT_PIN, DHT_TYPE);
HardwareSerial   co2Serial(2);

bool     adsOk     = false;
uint32_t readCount = 0;
uint32_t postOk    = 0;
uint32_t postFail  = 0;

// ── HELPERS ──────────────────────────────────────────────────
float rawToVolts(int16_t raw) { return raw * 0.000125f; }
float voltsToPpm(float v, float vz, float si) { return max((v - vz) * si, 0.0f); }

uint8_t co2Checksum(uint8_t* b) {
    uint8_t s = 0;
    for (int i = 1; i < 8; i++) s += b[i];
    return (~s) + 1;
}

int readCO2() {
    while (co2Serial.available()) co2Serial.read();
    co2Serial.write(CO2_CMD, 9);
    co2Serial.flush();
    unsigned long dl = millis() + 500;
    while (co2Serial.available() < 9 && millis() < dl);
    if (co2Serial.available() < 9) return -1;
    uint8_t r[9] = {};
    for (int i = 0; i < 9; i++) r[i] = co2Serial.read();
    if (r[0] != 0xFF || r[1] != 0x86) return -2;
    if (r[8] != co2Checksum(r))        return -3;
    return ((int)r[2] << 8) | r[3];
}

void printSep(const char* l = nullptr) {
    Serial.println(F("========================================"));
    if (l) Serial.println(l);
}

// ── WIFI CONNECT ─────────────────────────────────────────────
void connectWiFi() {
    Serial.printf("[WiFi]     Connecting to %s", WIFI_SSID);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    int tries = 0;
    while (WiFi.status() != WL_CONNECTED && tries < 20) {
        delay(500);
        Serial.print(".");
        tries++;
    }
    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("\n[WiFi]     Connected! IP: %s\n",
            WiFi.localIP().toString().c_str());
    } else {
        Serial.println(F("\n[WiFi]     FAILED — will retry each cycle"));
    }
}

// ── POST TO BACKEND ──────────────────────────────────────────
bool postReading(float co, float no2, int co2, float temp, float rh) {

    if (WiFi.status() != WL_CONNECTED) {
        Serial.println(F("[HTTP]     WiFi not connected — skipping POST"));
        return false;
    }

    // Build JSON
    StaticJsonDocument<256> doc;
    doc["deviceId"]    = DEVICE_ID;
    doc["co"]          = serialized(String(co,   2));
    doc["no2"]         = serialized(String(no2,  3));
    doc["co2"]         = co2 > 0 ? co2 : 0;
    doc["temperature"] = serialized(String(temp, 1));
    doc["humidity"]    = serialized(String(rh,   1));

    String payload;
    serializeJson(doc, payload);

    Serial.printf("[HTTP]     POST → %s\n", SERVER_URL);
    Serial.printf("[HTTP]     Body: %s\n", payload.c_str());

    WiFiClientSecure client;
    client.setInsecure();   // skip SSL cert check (Render uses Let's Encrypt)

    HTTPClient http;
    http.begin(client, SERVER_URL);
    http.addHeader("Content-Type", "application/json");
    http.setTimeout(10000);

    int code = http.POST(payload);

    if (code > 0) {
        String resp = http.getString();
        Serial.printf("[HTTP]     Response %d: %s\n", code, resp.c_str());
        http.end();
        if (code == 200 || code == 201) {
            postOk++;
            Serial.printf("[HTTP]     POST OK (total ok=%lu fail=%lu)\n", postOk, postFail);
            return true;
        }
    } else {
        Serial.printf("[HTTP]     POST FAILED error=%d: %s\n",
            code, http.errorToString(code).c_str());
    }

    http.end();
    postFail++;
    Serial.printf("[HTTP]     Stats: ok=%lu fail=%lu\n", postOk, postFail);
    return false;
}

// ── SETUP ────────────────────────────────────────────────────
void setup() {
    Serial.begin(115200);
    unsigned long t = millis();
    while (!Serial && millis() - t < 5000);
    delay(500);

    printSep("  NODE 4 — AIR QUALITY — BOOT");
    Serial.printf("  Device   : %s\n", DEVICE_ID);
    Serial.printf("  Backend  : %s\n", SERVER_URL);
    printSep();

    // ── ADS1115 FIRST ─────────────────────────────────────────
    Wire.begin(21, 22);
    Wire.setClock(100000);   // 100kHz — more stable than 400kHz default
    delay(100);

    int adsRetry = 5;
    while (adsRetry--) {
        if (ads.begin(0x48)) { adsOk = true; break; }
        Serial.printf("[ADS1115]  Retry... (%d left)\n", adsRetry);
        delay(300);
    }

    if (!adsOk) {
        Serial.println(F("[ADS1115]  FAIL"));
        Serial.println(F("           Fix: connect ADDR pin to GND on ADS1115"));
        Serial.println(F("           Continuing without CO/NO2 readings"));
    } else {
        ads.setGain(GAIN_ONE);
        ads.setDataRate(RATE_ADS1115_128SPS);
        Serial.println(F("[ADS1115]  OK — 0x48 @ 100kHz"));
    }

    // ── DHT22 ─────────────────────────────────────────────────
    pinMode(DHT_PIN, INPUT_PULLUP);
    dht.begin();
    delay(2000);
    Serial.println(F("[DHT22]    OK — GPIO26"));

    // ── MH-Z19C ───────────────────────────────────────────────
    co2Serial.begin(CO2_BAUD, SERIAL_8N1, CO2_RX_PIN, CO2_TX_PIN);
    delay(3000);
    int testCO2 = readCO2();
    if (testCO2 < 0)
        Serial.printf("[MH-Z19C]  WARNING code=%d — needs 60-180s warmup\n", testCO2);
    else
        Serial.printf("[MH-Z19C]  OK — %d ppm\n", testCO2);

    // ── WiFi ──────────────────────────────────────────────────
    connectWiFi();

    Serial.println(F("\nCSV_HEADER,SEQ,CO_PPM,NO2_PPM,CO2_PPM,TEMP_C,RH_%,ALARMS,POST_OK"));
    Serial.println(F("[BOOT]     Complete — readings every 10s\n"));
}

// ── LOOP ─────────────────────────────────────────────────────
void loop() {
    readCount++;
    uint8_t alarm = 0;

    // ── WiFi reconnect if dropped ─────────────────────────────
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println(F("[WiFi]     Reconnecting..."));
        connectWiFi();
    }

    // ── DHT22 ─────────────────────────────────────────────────
    float temp = dht.readTemperature();
    float rh   = dht.readHumidity();
    if (isnan(temp) || isnan(rh)) {
        delay(300);
        temp = dht.readTemperature();
        rh   = dht.readHumidity();
    }
    if (isnan(temp) || isnan(rh)) { alarm |= (1<<5); temp = -99; rh = 0; }
    else {
        if (temp > THR_TEMP) alarm |= (1<<3);
        if (rh   > THR_RH)   alarm |= (1<<4);
    }

    // ── ADS1115 ───────────────────────────────────────────────
    float co_ppm = 0, co_v = 0, no2_ppm = 0, no2_v = 0;
    if (adsOk) {
        int16_t rCO  = ads.readADC_SingleEnded(CH_CO);
        int16_t rNO2 = ads.readADC_SingleEnded(CH_NO2);
        co_v    = rawToVolts(rCO);
        no2_v   = rawToVolts(rNO2);
        co_ppm  = voltsToPpm(co_v,  CO_V_ZERO,  CO_SENS_INV);
        no2_ppm = voltsToPpm(no2_v, NO2_V_ZERO, NO2_SENS_INV);
        if (co_ppm  > THR_CO)  alarm |= (1<<0);
        if (no2_ppm > THR_NO2) alarm |= (1<<1);
    }

    // ── MH-Z19C ───────────────────────────────────────────────
    int co2 = readCO2();
    if (co2 > 0 && co2 > (int)THR_CO2) alarm |= (1<<2);

    // ── Print ─────────────────────────────────────────────────
    printSep("  SENSOR READINGS");
    Serial.printf("  SEQ       : %lu\n", readCount);

    if (alarm & (1<<5)) {
        Serial.println(F("  Temp      : DHT22 ERROR"));
        Serial.println(F("  Humidity  : DHT22 ERROR"));
    } else {
        Serial.printf("  Temp      : %.1f C%s\n",  temp, (alarm&(1<<3)) ? "  *** HIGH ***" : "");
        Serial.printf("  Humidity  : %.1f %%%s\n", rh,   (alarm&(1<<4)) ? "  *** HIGH ***" : "");
    }

    if (adsOk) {
        Serial.printf("  CO        : %.2f ppm  (%.4fV)%s\n",
            co_ppm,  co_v,  (alarm&(1<<0)) ? "  *** ALARM ***" : "");
        Serial.printf("  NO2       : %.3f ppm  (%.4fV)%s\n",
            no2_ppm, no2_v, (alarm&(1<<1)) ? "  *** ALARM ***" : "");
    } else {
        Serial.println(F("  CO        : ADS1115 FAIL — check ADDR pin to GND"));
        Serial.println(F("  NO2       : ADS1115 FAIL — check ADDR pin to GND"));
    }

    if (co2 > 0) Serial.printf("  CO2       : %d ppm%s\n",
        co2, (alarm&(1<<2)) ? "  *** HIGH ***" : "");
    else Serial.printf("  CO2       : ERROR (code=%d) — warming up\n", co2);

    Serial.printf("  Alarms    : 0x%02X\n", alarm);
    Serial.printf("  WiFi      : %s\n",
        WiFi.status() == WL_CONNECTED ? WiFi.localIP().toString().c_str() : "DISCONNECTED");

    // ── POST to backend ───────────────────────────────────────
    bool posted = false;
    if (co2 > 0 || adsOk) {   // only post if at least one sensor has data
        posted = postReading(co_ppm, no2_ppm, co2 > 0 ? co2 : 0, temp, rh);
    }

    printSep();
    Serial.println();

    // ── CSV ───────────────────────────────────────────────────
    Serial.printf("DATA,%lu,%.2f,%.3f,%d,%.1f,%.1f,0x%02X,%d\n",
        readCount, co_ppm, no2_ppm,
        co2 > 0 ? co2 : 0, temp, rh,
        alarm, posted ? 1 : 0);

    delay(READ_INTERVAL_MS);
}