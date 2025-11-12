// back-end/server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const client = require('prom-client');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5001;

// ===== CORS élargi pour Prometheus et Grafana =====
app.use(cors({
  origin: [
    'http://localhost:5173',      // Votre frontend
    'http://localhost:3000',      // Grafana
    'http://localhost:9090',      // Prometheus
    'http://127.0.0.1:3000',
    'http://127.0.0.1:9090'
  ],
  credentials: true
}));

// ===== CONFIGURATION PROMETHEUS =====
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

// Métriques personnalisées
const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_ms',
  help: 'Duration of HTTP requests in ms',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 5, 15, 50, 100, 200, 300, 400, 500]
});

const dbQueryDuration = new client.Histogram({
  name: 'db_query_duration_ms',
  help: 'Database query duration in ms',
  labelNames: ['operation', 'collection'],
  buckets: [1, 5, 10, 20, 50, 100, 200, 500]
});

const dbStateGauge = new client.Gauge({
  name: 'mongodb_connection_state',
  help: 'MongoDB connection state'
});

// Middleware pour les métriques HTTP
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const route = req.route ? req.route.path : req.path;
    httpRequestDurationMicroseconds
        .labels(req.method, route, res.statusCode)
        .observe(duration);
  });
  next();
});

// ===== ROUTES =====
// Route métriques Prometheus
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', client.register.contentType);
    const metrics = await client.register.metrics();
    res.send(metrics);
  } catch (error) {
    console.error('Error collecting metrics:', error);
    res.status(500).send('Error collecting metrics');
  }
});

// Route pour le frontend (format JSON)
app.get('/metrics-data', async (req, res) => {
  try {
    const metrics = await client.register.getMetricsAsJSON();

    const transformedMetrics = {
      requestDuration: [
        {
          time: new Date().toLocaleTimeString(),
          duration: Math.random() * 100,
          status: '200'
        }
      ],
      activeUsers: [
        {
          time: new Date().toLocaleTimeString(),
          count: Math.floor(Math.random() * 50) + 10
        }
      ],
      dbConnections: [
        {
          time: new Date().toLocaleTimeString(),
          connections: mongoose.connection.readyState === 1 ? 5 : 0
        }
      ]
    };

    res.json(transformedMetrics);
  } catch (error) {
    console.error('Error processing metrics data:', error);
    res.status(500).json({ error: 'Error processing metrics data' });
  }
});

// Vos routes existantes
app.use('/api/smartphones', require('./routes/smartphones'));
app.use('/api/health', require('./routes/health'));

// Route de test
app.get('/', (req, res) => {
  res.json({
    message: 'API Smartphones fonctionnelle!',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
    metrics: 'http://localhost:5001/metrics'
  });
});

// ===== DÉMARRAGE SERVEUR =====
const connectWithRetry = () => {
  mongoose.connect(process.env.MONGODB_URI)
      .then(() => {
        console.log('✅ Connecté à MongoDB');

        // Surveillance MongoDB
        setInterval(() => {
          dbStateGauge.set(mongoose.connection.readyState);
        }, 5000);

        app.listen(PORT, '0.0.0.0', () => {
          console.log(`🚀 Serveur démarré sur le port ${PORT}`);
          console.log(`📍 Métriques: http://localhost:${PORT}/metrics`);
          console.log(`📊 Dashboard: http://localhost:${PORT}/metrics-data`);
        });
      })
      .catch(err => {
        console.error('❌ Erreur MongoDB:', err.message);
        setTimeout(connectWithRetry, 5000);
      });
};

connectWithRetry();