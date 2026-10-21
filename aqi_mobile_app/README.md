# AeroWatch - Air Quality Monitoring Mobile Application

A cross-platform Flutter mobile application designed for real-time environmental telemetry and air quality monitoring. It connects seamlessly to the live hosted Render backend at `https://aqi-monitoring-project.onrender.com` or local ESP32 hardware instances.

---

## 📱 Features

- **Real-Time AQI Hero Gauge**: Custom animated curved gauge with dynamic color shifting (Emerald Green, Amber, Orange, Crimson Red, Purple, Maroon) reflecting the current EPA/composite air quality index.
- **Gas Sensor Telemetry Cards**:
  - **CO₂ (Carbon Dioxide)**: Calibrated PPM scale with pure / drowsiness / hazard thresholds.
  - **CO (Carbon Monoxide)**: Parts-per-million detection with safety limits.
  - **NO₂ (Nitrogen Dioxide)**: Parts-per-billion detection with sensitive group alert badges.
- **Microclimate Monitoring**: Glassmorphic cards for Temperature (°C) and Relative Humidity (%) with comfort ratings.
- **Live Sync Bar**:
  - Live connection status to Render backend (`https://aqi-monitoring-project.onrender.com`).
  - Active countdown timer for auto-polling.
  - Play / Pause polling toggle & instant manual refresh.
- **Interactive Telemetry Curves**: `fl_chart` line graph plotting the last 20 sensor telemetry transmissions with interactive touch tooltips and metric switcher (AQI, CO₂, NO₂, Temp, Humidity).
- **Health Advisories**: Contextual guidance on face masks (N95), room ventilation, outdoor exercise suitability, and air purifier fan speeds.
- **History & Transmission Logs**: Chronological log of past sensor transmissions with device ID (`ESP32_002`), exact timestamps, and reading metrics.
- **Settings & Diagnostic Suite**:
  - Configurable Backend API Endpoint with one-tap ping & MongoDB database health inspection (`/api/health`).
  - Polling interval adjustment (3s, 5s, 10s, 30s).
  - Built-in Simulation / Mock Walk generator for offline demoing.
  - Test telemetry transmitter to simulate ESP32 packets to the live database (`POST /api/readings`).
  - Theme toggler: Sleek Deep Obsidian dark mode & bright clean light mode.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24.0 or newer)
- Android SDK / Physical Android device or Emulator / Chrome for Web preview

### Running the App

1. Open a terminal in the mobile app directory:
   ```bash
   cd aqi_mobile_app
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run on your connected device (e.g., your Samsung Galaxy `SM E146B` or Chrome):
   ```bash
   # Run on connected phone
   flutter run -d RZCWA07ACND

   # Or run in Google Chrome
   flutter run -d chrome
   ```

4. Build Release Android APK:
   ```bash
   flutter build apk --release
   ```
   The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📡 Backend Endpoints Used

| Endpoint | Method | Description |
|---|---|---|
| `https://aqi-monitoring-project.onrender.com/api/readings/latest` | GET | Fetches the latest sensor packet |
| `https://aqi-monitoring-project.onrender.com/api/readings?limit=20` | GET | Fetches past 20 sensor packets for charts |
| `https://aqi-monitoring-project.onrender.com/api/health` | GET | Verifies API and MongoDB database status |
| `https://aqi-monitoring-project.onrender.com/api/readings` | POST | Ingests new sensor readings from ESP32 |
