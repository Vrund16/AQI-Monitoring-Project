# AeroWatch - Air Quality Monitoring Mobile Application

A cross-platform Flutter mobile application for real-time environmental telemetry. It reads the same live Render API endpoint as the AeroWatch web dashboard:
`https://aqi-monitoring-project.onrender.com/api/readings/latest`.

---

## 📱 Features

- **Real-Time AQI Hero Gauge**: Custom animated curved gauge with dynamic color shifting (Emerald Green, Amber, Orange, Crimson Red, Purple, Maroon) reflecting the same composite score and category thresholds as the web dashboard.
- **Gas Sensor Telemetry Cards**:
  - **CO₂ (Carbon Dioxide)**: Calibrated PPM scale with pure / drowsiness / hazard thresholds.
  - **CO (Carbon Monoxide)**: Parts-per-million detection with safety limits.
  - **NO₂ (Nitrogen Dioxide)**: Parts-per-billion detection with sensitive group alert badges.
- **Microclimate Monitoring**: Glassmorphic cards for Temperature (°C) and Relative Humidity (%) with comfort ratings.
- **Live Sync Bar**:
  - Live connection status to Render backend (`https://aqi-monitoring-project.onrender.com`).
  - Five-second polling countdown, matching the web dashboard.
  - Play / Pause polling toggle & instant manual refresh.
- **Interactive Telemetry Curves**: `fl_chart` line graph plotting recent backend history with interactive touch tooltips and metric switcher (AQI, CO₂, NO₂, Temp, Humidity).
- **Health Advisories**: Contextual guidance on face masks (N95), room ventilation, outdoor exercise suitability, and air purifier fan speeds.
- **History & Transmission Logs**: Chronological log of past sensor transmissions with device ID (`ESP32_002`), exact timestamps, and reading metrics.
- **Settings & Diagnostic Suite**:
  - Configurable full readings endpoint with one-tap ping & MongoDB database health inspection (`/api/health`).
  - Uses live API readings only; connection failures are shown instead of replacing sensor data with simulated values.
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
