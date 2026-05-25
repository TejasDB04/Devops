// Simple Node.js Express Application
const express = require('express');
const client = require('prom-client');
const app = express();

const PORT = process.env.PORT || 3000;

// Prometheus default metrics (CPU, memory, event loop, etc.)
client.collectDefaultMetrics({ prefix: 'k8s_app_' });

const httpRequestDuration = new client.Histogram({
  name: 'k8s_app_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5]
});

const httpRequestsTotal = new client.Counter({
  name: 'k8s_app_http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

function log(level, message, extra = {}) {
  console.log(JSON.stringify({
    level,
    message,
    timestamp: new Date().toISOString(),
    hostname: process.env.HOSTNAME || 'unknown',
    ...extra
  }));
}

// Middleware
app.use(express.json());

app.use((req, res, next) => {
  const start = process.hrtime.bigint();
  res.on('finish', () => {
    const durationSec = Number(process.hrtime.bigint() - start) / 1e9;
    const route = req.route?.path || req.path;
    const labels = { method: req.method, route, status_code: String(res.statusCode) };
    httpRequestDuration.observe(labels, durationSec);
    httpRequestsTotal.inc(labels);
  });
  next();
});

// Routes
app.get('/', (req, res) => {
  res.json({
  message: 'Welcome to My Kubernetes App v2!',  // ← Change this
  timestamp: new Date().toISOString(),
  hostname: process.env.HOSTNAME || 'unknown'
});
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', uptime: process.uptime() });
});

app.get('/api/info', (req, res) => {
  res.json({
    app: 'Node.js K8s App',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    pod: process.env.HOSTNAME
  });
});

app.get('/api/version', (req, res) => {
  res.json({
    version: '2.0.0',
    timestamp: new Date().toISOString(),
    message: 'Updated with zero downtime!',
    deployment: 'Rolling update successful'
  });
});

app.post('/api/echo', (req, res) => {
  res.json({ echo: req.body });
});

// Prometheus scrape endpoint (used by Prometheus in monitoring namespace)
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Error handling
app.use((err, req, res, next) => {
  log('error', err.message, { path: req.path, method: req.method });
  res.status(500).json({ error: err.message });
});

function startServer(port = PORT) {
  return app.listen(port, () => {
    log('info', 'Server started', { port, nodeVersion: process.version });
  });
}

if (require.main === module) {
  startServer();
}

module.exports = { app, startServer };
