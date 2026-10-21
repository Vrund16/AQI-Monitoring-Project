# Real-Time Air Quality Monitoring System (AQI)

A full-stack, cross-platform environmental monitoring system featuring an IoT backend, web dashboard, and Flutter mobile application.

---

## 📂 Repository Structure

- [**aqi_mobile_app/**](file:///d:/New%20folder/aqi_mobile_app): Flutter mobile application (iOS & Android) with live telemetry gauge, interactive trends charts, health advisories, and settings.
- [**Frontend/**](file:///d:/New%20folder/Frontend): Vite + React + TypeScript web dashboard with Chart.js charts and live polling.
- [**backend/**](file:///d:/New%20folder/backend): Node.js + Express + MongoDB REST API for ingesting and serving sensor readings from ESP32 microcontrollers.

---

## 🌐 Live Hosted Backend API

The backend is deployed and running on Render:
- **Base URL**: `https://aqi-monitoring-project.onrender.com`
- **Latest Reading**: `https://aqi-monitoring-project.onrender.com/api/readings/latest`
- **Historical Readings**: `https://aqi-monitoring-project.onrender.com/api/readings?limit=20`
- **Server Health**: `https://aqi-monitoring-project.onrender.com/api/health`

---

## 📲 Flutter Mobile App Quickstart

```bash
cd aqi_mobile_app
flutter pub get
flutter run
```
