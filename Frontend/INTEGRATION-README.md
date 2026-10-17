# EcoSense AQI Dashboard — Safe Integration Patch

This package preserves the original React UI and app logic. The only code change is the default Render endpoint URL. Mock Generator Mode remains enabled by default, matching the original project, so the dashboard continues to work with simulated readings until live API integration is deliberately enabled.

## Run locally
1. Install Node.js compatible with the Vite version in package.json.
2. In this folder run `npm install`.
3. Run `npm run dev`.

## Enable live backend
1. Open the dashboard's API settings.
2. Set the endpoint to `https://aqi-monitoring-project.onrender.com/api/readings/latest`.
3. Uncheck **Force Mock Generator Mode** and use **Test Ping**.

Important: this is a conservative configuration patch, not a claim of end-to-end validation. The existing fetch logic expects a direct sensor object with temperature, humidity, co2, co and no2 fields. If the backend response uses a wrapper object, the adapter must be updated after checking the actual response.
