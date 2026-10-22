import { useCallback, useEffect, useState } from 'react';
import {
  Activity,
  AirVent,
  Check,
  ChevronDown,
  CircleAlert,
  Cloud,
  CloudCog,
  Droplets,
  ExternalLink,
  FlaskConical,
  Leaf,
  LoaderCircle,
  Moon,
  Pause,
  Play,
  RefreshCw,
  Settings2,
  ShieldCheck,
  Sun,
  Thermometer,
  Wind,
  X,
} from 'lucide-react';

interface SensorReading {
  deviceId: string;
  temperature: number;
  humidity: number;
  co2: number;
  co: number;
  no2: number;
  timestamp: string;
}

interface TrendPoint {
  timestamp: number;
  temperature: number;
  humidity: number;
  co2: number;
}

const DEFAULT_API_URL = import.meta.env.VITE_API_URL?.trim()
  || 'https://aqi-monitoring-project.onrender.com/api/readings/latest';
const REFRESH_SECONDS = 5;
const MAX_TREND_POINTS = 20;

function parseReading(payload: unknown): SensorReading {
  if (!payload || typeof payload !== 'object') {
    throw new Error('The API returned an invalid response.');
  }

  const response = payload as Record<string, unknown>;
  const data = response.data && typeof response.data === 'object'
    ? response.data as Record<string, unknown>
    : response;
  const values = {
    temperature: Number(data.temperature),
    humidity: Number(data.humidity),
    co2: Number(data.co2),
    co: Number(data.co),
    no2: Number(data.no2),
  };

  if (Object.values(values).some((value) => !Number.isFinite(value))) {
    throw new Error('The API response is missing valid sensor readings.');
  }

  const timestamp = data.createdAt ?? data.timestamp;
  return {
    deviceId: typeof data.deviceId === 'string' ? data.deviceId : 'ESP32_DEV',
    ...values,
    timestamp: typeof timestamp === 'string' ? timestamp : new Date().toISOString(),
  };
}

function getAqi(score: number) {
  if (score <= 50) return { label: 'Good', color: 'green' };
  if (score <= 100) return { label: 'Moderate', color: 'amber' };
  if (score <= 150) return { label: 'Unhealthy for sensitive groups', color: 'orange' };
  if (score <= 200) return { label: 'Unhealthy', color: 'red' };
  if (score <= 300) return { label: 'Very unhealthy', color: 'purple' };
  return { label: 'Hazardous', color: 'maroon' };
}

function getHealthAdvice(score: number) {
  if (score <= 50) {
    return 'Air quality is pristine. Conditions are suitable for outdoor activities and fresh ventilation.';
  }
  if (score <= 100) {
    return 'Air quality is acceptable. Sensitive individuals may consider limiting prolonged outdoor exertion.';
  }
  if (score <= 150) {
    return 'Pollutant levels are elevated. Sensitive groups may experience symptoms; consider reducing prolonged outdoor activity.';
  }
  return 'Pollutant levels are high. Limit outdoor exposure, improve indoor filtration, and monitor conditions.';
}

function getAlert(value: number, warning: number, danger: number) {
  if (value >= danger) return { label: 'Hazard', tone: 'red' };
  if (value >= warning) return { label: 'Warning', tone: 'amber' };
  return { label: 'Safe', tone: 'green' };
}

function formatTime(value?: string | number) {
  if (!value) return '--:--:--';
  return new Date(value).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

function TrendChart({
  points,
  metric,
  color,
  unit,
  value,
}: {
  points: TrendPoint[];
  metric: 'temperature' | 'humidity' | 'co2';
  color: string;
  unit: string;
  value: number;
}) {
  const chartWidth = 600;
  const chartHeight = 150;
  const pad = 10;
  const values = points.map((point) => point[metric]);
  const min = values.length ? Math.min(...values) : 0;
  const max = values.length ? Math.max(...values) : 1;
  const spread = Math.max(max - min, 1);
  const coordinates = points.map((point, index) => ({
    x: points.length === 1 ? chartWidth / 2 : pad + (index / (points.length - 1)) * (chartWidth - pad * 2),
    y: chartHeight - pad - ((point[metric] - min) / spread) * (chartHeight - pad * 2),
  }));
  const path = coordinates.map((point, index) =>
    `${index === 0 ? 'M' : 'L'} ${point.x} ${point.y}`,
  ).join(' ');
  const fillPath = coordinates.length
    ? `${path} L ${coordinates[coordinates.length - 1].x} ${chartHeight} L ${coordinates[0].x} ${chartHeight} Z`
    : '';

  return (
    <article className="panel trend-card">
      <div className="panel-heading">
        <div className="trend-title">
          <span className={`metric-dot ${color}`} />
          <div>
            <h3>{metric === 'co2' ? 'CO₂ concentration' : metric === 'temperature' ? 'Temperature' : 'Humidity'}</h3>
            <p>Recent live readings</p>
          </div>
        </div>
        <strong className="trend-current">
          {metric === 'temperature' ? value.toFixed(1) : metric === 'humidity' ? value.toFixed(1) : Math.round(value)}
          <span>{unit}</span>
        </strong>
      </div>
      {points.length < 2 ? (
        <div className="chart-empty">
          <Activity size={18} />
          <span>Trend appears as live readings arrive</span>
        </div>
      ) : (
        <div className="chart-wrap">
          <svg viewBox={`0 0 ${chartWidth} ${chartHeight}`} role="img" aria-label={`${metric} live trend`}>
            <defs>
              <linearGradient id={`fill-${metric}`} x1="0" x2="0" y1="0" y2="1">
                <stop offset="0%" stopColor="currentColor" stopOpacity=".24" />
                <stop offset="100%" stopColor="currentColor" stopOpacity="0" />
              </linearGradient>
            </defs>
            {[0.25, 0.5, 0.75].map((fraction) => (
              <line
                key={fraction}
                x1="0"
                x2={chartWidth}
                y1={chartHeight * fraction}
                y2={chartHeight * fraction}
                className="chart-grid-line"
              />
            ))}
            <path d={fillPath} fill={`url(#fill-${metric})`} className={`chart-area ${color}`} />
            <path d={path} fill="none" className={`chart-line ${color}`} />
            {coordinates.length > 0 && (
              <circle
                cx={coordinates[coordinates.length - 1].x}
                cy={coordinates[coordinates.length - 1].y}
                r="4"
                className={`chart-point ${color}`}
              />
            )}
          </svg>
          <div className="chart-time-labels">
            <span>{formatTime(points[0]?.timestamp)}</span>
            <span>{formatTime(points[points.length - 1]?.timestamp)}</span>
          </div>
        </div>
      )}
    </article>
  );
}

export default function App() {
  const [apiUrl, setApiUrl] = useState(DEFAULT_API_URL);
  const [draftUrl, setDraftUrl] = useState(DEFAULT_API_URL);
  const [reading, setReading] = useState<SensorReading | null>(null);
  const [trend, setTrend] = useState<TrendPoint[]>([]);
  const [lastUpdated, setLastUpdated] = useState<number>();
  const [countdown, setCountdown] = useState(REFRESH_SECONDS);
  const [isPolling, setIsPolling] = useState(true);
  const [isDark, setIsDark] = useState(true);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string>();
  const [connectionMessage, setConnectionMessage] = useState<string>();

  const fetchLatest = useCallback(async () => {
    setIsLoading(true);
    const controller = new AbortController();
    const timeout = window.setTimeout(() => controller.abort(), 12000);

    try {
      const response = await fetch(apiUrl, {
        headers: { Accept: 'application/json' },
        signal: controller.signal,
      });
      if (!response.ok) throw new Error(`Server returned HTTP ${response.status}.`);

      const next = parseReading(await response.json());
      const receivedAt = Date.now();
      setReading(next);
      setLastUpdated(receivedAt);
      setError(undefined);
      setConnectionMessage(undefined);
      setTrend((current) => [
        ...current,
        {
          timestamp: receivedAt,
          temperature: next.temperature,
          humidity: next.humidity,
          co2: next.co2,
        },
      ].slice(-MAX_TREND_POINTS));
    } catch (cause) {
      const message = cause instanceof Error
        ? cause.name === 'AbortError' ? 'The API request timed out.' : cause.message
        : 'Unable to load sensor readings.';
      setError(message);
      setConnectionMessage('Could not connect to the live readings API.');
    } finally {
      window.clearTimeout(timeout);
      setIsLoading(false);
      setCountdown(REFRESH_SECONDS);
    }
  }, [apiUrl]);

  useEffect(() => {
    if (!isPolling) return undefined;
    void fetchLatest();
    const interval = window.setInterval(() => void fetchLatest(), REFRESH_SECONDS * 1000);
    return () => window.clearInterval(interval);
  }, [fetchLatest, isPolling]);

  useEffect(() => {
    setCountdown(REFRESH_SECONDS);
    if (!isPolling) return undefined;
    const timer = window.setInterval(() => {
      setCountdown((remaining) => remaining <= 1 ? REFRESH_SECONDS : remaining - 1);
    }, 1000);
    return () => window.clearInterval(timer);
  }, [isPolling, apiUrl]);

  const saveApiUrl = () => {
    const nextUrl = draftUrl.trim();
    if (!nextUrl) {
      setConnectionMessage('Enter a readings API URL before saving.');
      return;
    }
    try {
      const parsed = new URL(nextUrl);
      if (!['https:', 'http:'].includes(parsed.protocol)) throw new Error();
    } catch {
      setConnectionMessage('Enter a valid HTTP or HTTPS API URL.');
      return;
    }
    setApiUrl(nextUrl);
    setIsSettingsOpen(false);
  };

  const testConnection = async () => {
    setConnectionMessage('Checking the readings API…');
    const startedAt = performance.now();
    try {
      const response = await fetch(draftUrl.trim(), { headers: { Accept: 'application/json' } });
      if (!response.ok) throw new Error(`Server returned HTTP ${response.status}.`);
      parseReading(await response.json());
      setConnectionMessage(`Connected successfully (${Math.round(performance.now() - startedAt)} ms).`);
    } catch (cause) {
      setConnectionMessage(cause instanceof Error ? cause.message : 'API connection failed.');
    }
  };

  const score = reading
    ? Math.min(500, Math.max(0, Math.round(reading.co2 / 20 + reading.co * 8 + reading.no2 * 0.8)))
    : 0;
  const aqi = getAqi(score);
  const isDanger = (reading?.co2 ?? 0) >= 1500 || (reading?.co ?? 0) >= 25 || (reading?.no2 ?? 0) >= 100;

  return (
    <div className={`app-shell ${isDark ? 'theme-dark' : 'theme-light'}`}>
      <header className="topbar">
        <a className="brand" href="/" aria-label="AeroWatch dashboard home">
          <span className="brand-icon"><Wind size={22} /></span>
          <span className="brand-copy">
            <strong>AeroWatch</strong>
            <small>Air Quality Monitoring System</small>
          </span>
        </a>

        <div className="topbar-actions">
          <div className={`connection-pill ${error ? 'offline' : reading ? 'online' : 'pending'}`}>
            <span className="connection-dot" />
            <span>{error ? 'Offline' : reading ? 'Render Live' : 'Connecting'}</span>
          </div>
          <button className="icon-button" onClick={() => void fetchLatest()} aria-label="Refresh readings" title="Refresh now">
            <RefreshCw size={18} className={isLoading ? 'spin' : ''} />
          </button>
          <button className="icon-button" onClick={() => setIsDark((value) => !value)} aria-label="Toggle color theme" title="Toggle theme">
            {isDark ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <button className="icon-button" onClick={() => { setDraftUrl(apiUrl); setIsSettingsOpen(true); }} aria-label="Open API settings" title="API settings">
            <Settings2 size={18} />
          </button>
        </div>
      </header>

      <main className="dashboard">
        <section className="welcome-row">
          <div>
            <div className="eyebrow"><span className="eyebrow-line" /> REAL-TIME ENVIRONMENT</div>
            <h1>Air quality <span>at a glance.</span></h1>
            <p>Live sensor readings from your AeroWatch monitoring device.</p>
          </div>
          <div className="last-sync">
            <span className="sync-icon"><RefreshCw size={14} /></span>
            <div>
              <span>LAST UPDATED</span>
              <strong>{formatTime(lastUpdated)}</strong>
            </div>
            <span className="sync-divider" />
            <span className="refresh-count">{isPolling ? `Refresh in ${countdown}s` : 'Auto-refresh paused'}</span>
            <button className="pause-button" onClick={() => setIsPolling((value) => !value)} aria-label={isPolling ? 'Pause auto refresh' : 'Resume auto refresh'}>
              {isPolling ? <Pause size={15} /> : <Play size={15} />}
            </button>
          </div>
        </section>

        {error && (
          <div className="error-banner" role="status">
            <CircleAlert size={18} />
            <div><strong>Live readings are unavailable</strong><span>{error}</span></div>
            <button onClick={() => void fetchLatest()}>Try again</button>
          </div>
        )}

        {connectionMessage && !isSettingsOpen && (
          <div className="inline-message" role="status">{connectionMessage}</div>
        )}

        <section className="overview-grid">
          <article className={`panel aqi-panel aqi-${aqi.color}`}>
            <div className="aqi-panel-top">
              <div className="device-chip"><CloudCog size={15} /><span>{reading?.deviceId ?? 'AeroWatch Sensor'}</span></div>
              <span className="monitor-chip"><span /> LIVE MONITOR</span>
            </div>
            <div className="aqi-content">
              <div className="gauge-wrap" aria-label={`Air quality index ${score}`}>
                <svg className="aqi-gauge" viewBox="0 0 240 150" role="img" aria-hidden="true">
                  <path className="gauge-track" d="M 25 125 A 95 95 0 0 1 215 125" />
                  <path className="gauge-progress" d="M 25 125 A 95 95 0 0 1 215 125" pathLength="100" style={{ strokeDasharray: `${Math.min(score / 300, 1) * 100} 100` }} />
                </svg>
                <div className="gauge-value">
                  {reading ? <strong>{score}</strong> : <LoaderCircle size={32} className="spin" />}
                  <span>AIR QUALITY INDEX</span>
                </div>
              </div>
              <div className={`aqi-status status-${aqi.color}`}>
                <ShieldCheck size={17} />
                <span>{aqi.label}</span>
              </div>
              <p className="aqi-advice">
                {reading ? getHealthAdvice(score) : 'Waiting for the first live sensor reading.'}
              </p>
            </div>
            <div className="aqi-footer">
              <span><Activity size={14} /> Composite sensor index</span>
              <span>Scale 0–500</span>
            </div>
          </article>

          <div className="environment-column">
            <article className="panel environment-card temperature-card">
              <div className="environment-top">
                <span className="environment-icon temp-icon"><Thermometer size={20} /></span>
                <span className="comfort-tag">{reading ? reading.temperature > 26 ? 'Warm' : reading.temperature < 18 ? 'Cool' : 'Comfortable' : 'Waiting'}</span>
              </div>
              <span className="environment-label">Temperature</span>
              <div className="environment-reading">{reading ? reading.temperature.toFixed(1) : '--'}<small>°C</small></div>
              <div className="environment-foot"><span>Ambient temperature</span><Sun size={15} /></div>
            </article>

            <article className="panel environment-card humidity-card">
              <div className="environment-top">
                <span className="environment-icon humidity-icon"><Droplets size={20} /></span>
                <span className="comfort-tag">{reading ? reading.humidity > 60 ? 'Humid' : reading.humidity < 30 ? 'Dry' : 'Optimal' : 'Waiting'}</span>
              </div>
              <span className="environment-label">Humidity</span>
              <div className="environment-reading">{reading ? reading.humidity.toFixed(1) : '--'}<small>%</small></div>
              <div className="environment-foot"><span>Relative humidity</span><Droplets size={15} /></div>
            </article>

            <article className={`panel live-source ${error ? 'source-error' : ''}`}>
              <div className="source-icon"><Cloud size={18} /></div>
              <div className="source-copy">
                <strong>{error ? 'API connection issue' : 'Live Render data'}</strong>
                <span>{error ? 'Check your connection or endpoint' : 'Synced from your sensor backend'}</span>
              </div>
              <span className="source-indicator"><span /></span>
            </article>
          </div>
        </section>

        <section className="sensor-section">
          <div className="section-heading">
            <div className="section-title">
              <span className="section-icon"><AirVent size={17} /></span>
              <div><h2>Gas sensor telemetry</h2><p>Live pollutant concentrations</p></div>
            </div>
            <span className="device-label"><span className="device-dot" /> DEVICE <strong>{reading?.deviceId ?? '—'}</strong></span>
          </div>
          <div className="sensor-grid">
            {[
              { key: 'co2' as const, title: 'Carbon dioxide', symbol: 'CO₂', unit: 'ppm', icon: Cloud, warning: 1000, danger: 1500, max: 2000, color: 'violet' },
              { key: 'co' as const, title: 'Carbon monoxide', symbol: 'CO', unit: 'ppm', icon: ShieldCheck, warning: 9, danger: 25, max: 50, color: 'orange' },
              { key: 'no2' as const, title: 'Nitrogen dioxide', symbol: 'NO₂', unit: 'ppb', icon: FlaskConical, warning: 54, danger: 100, max: 150, color: 'cyan' },
            ].map((sensor) => {
              const value = reading?.[sensor.key] ?? 0;
              const alert = getAlert(value, sensor.warning, sensor.danger);
              const Icon = sensor.icon;
              return (
                <article key={sensor.key} className={`panel sensor-card metric-${sensor.color} ${alert.tone === 'red' ? 'sensor-danger' : ''}`}>
                  <div className="sensor-card-top">
                    <div className="sensor-name">
                      <span className="sensor-icon"><Icon size={18} /></span>
                      <div><strong>{sensor.symbol}</strong><span>{sensor.title}</span></div>
                    </div>
                    <span className={`alert-badge badge-${alert.tone}`}><span />{alert.label}</span>
                  </div>
                  <div className="sensor-value">
                    <strong>{reading ? sensor.key === 'co2' ? Math.round(value) : value.toFixed(1) : '--'}</strong>
                    <span>{sensor.unit}</span>
                  </div>
                  <div className="meter-track"><span style={{ width: `${Math.min((value / sensor.max) * 100, 100)}%` }} /></div>
                  <div className="sensor-range"><span>0–{sensor.max} {sensor.unit}</span><span>{sensor.warning}+ warning</span></div>
                </article>
              );
            })}
          </div>
        </section>

        <section className="trends-section">
          <div className="section-heading">
            <div className="section-title">
              <span className="section-icon"><Activity size={17} /></span>
              <div><h2>Environmental trends</h2><p>Built from live API polls · last {MAX_TREND_POINTS} readings</p></div>
            </div>
            <span className="live-label"><span /> UPDATING EVERY 5 SECONDS</span>
          </div>
          <div className="trend-grid">
            <TrendChart points={trend} metric="temperature" color="orange" unit="°C" value={reading?.temperature ?? 0} />
            <TrendChart points={trend} metric="humidity" color="cyan" unit="%" value={reading?.humidity ?? 0} />
            <TrendChart points={trend} metric="co2" color="violet" unit="ppm" value={reading?.co2 ?? 0} />
          </div>
        </section>

        <footer className="dashboard-footer">
          <div><Leaf size={15} /><span>AeroWatch <b>·</b> Environmental intelligence</span></div>
          <span>Readings API <code>{apiUrl}</code></span>
          <button onClick={() => { setDraftUrl(apiUrl); setIsSettingsOpen(true); }}>API settings <ChevronDown size={14} /></button>
        </footer>
      </main>

      {isSettingsOpen && (
        <div className="modal-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) setIsSettingsOpen(false); }}>
          <section className="settings-modal" role="dialog" aria-modal="true" aria-labelledby="settings-title">
            <div className="modal-heading">
              <div className="modal-title-icon"><Settings2 size={19} /></div>
              <div><h2 id="settings-title">API connection</h2><p>Choose the live readings endpoint for this dashboard.</p></div>
              <button className="icon-button" onClick={() => setIsSettingsOpen(false)} aria-label="Close settings"><X size={18} /></button>
            </div>
            <label className="input-label" htmlFor="api-url">Readings API URL</label>
            <input
              id="api-url"
              className="api-input"
              type="url"
              value={draftUrl}
              onChange={(event) => setDraftUrl(event.target.value)}
              onKeyDown={(event) => { if (event.key === 'Enter') saveApiUrl(); }}
              placeholder={DEFAULT_API_URL}
            />
            <div className="endpoint-hint"><ExternalLink size={14} /><span>Use the full endpoint ending in <code>/api/readings/latest</code>.</span></div>
            {connectionMessage && <div className="connection-message" role="status">{connectionMessage}</div>}
            <div className="modal-actions">
              <button className="secondary-button" onClick={() => { setDraftUrl(DEFAULT_API_URL); setConnectionMessage(undefined); }}>Reset to Render API</button>
              <button className="secondary-button" onClick={() => void testConnection()}>Test connection</button>
              <button className="primary-button" onClick={saveApiUrl}><Check size={16} /> Save & refresh</button>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}
