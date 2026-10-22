# EcoSense AQI Dashboard — Render API Integration

The React dashboard and both standalone HTML versions read live sensor data by default from the Render endpoint:
`https://aqi-monitoring-project.onrender.com/api/readings/latest`

For the hosted React frontend, set `VITE_API_URL` to this full endpoint in the frontend Render service's Environment settings, then redeploy. The standalone HTML files use the default URL directly.

The API returns the latest reading inside a `data` property. The dashboard unwraps that response and displays the live temperature, humidity, CO₂, CO and NO₂ values. If the API is unavailable, the standalone versions fall back to simulated readings and the React dashboard reports a connection error.

## Run locally
1. Install Node.js compatible with the Vite version in package.json.
2. In this folder run `npm install`.
3. Run `npm run dev`.

## Configure the endpoint
Open the dashboard's API settings to change the URL or enable **Force Mock Generator Mode**. Use **Test Ping** to check connectivity.
