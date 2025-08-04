// server.js
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
require('dotenv').config();
console.log('✅ WEBHOOK_SECRET:', process.env.WEBHOOK_SECRET);

const requestLogger = require('./middleware/requestLogger');
const errorHandler = require('./middleware/errorHandler');
const paymentRoutes = require('./routes/payments');
const webhookRoutes = require('./routes/webhooks');
const ReconciliationJob = require('./jobs/reconciliation');
const pool = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors());

// Raw body parser middleware for webhook route
app.use('/api/webhooks', express.json({
  limit: '10mb',
  verify: (req, res, buf) => {
    if (buf && buf.length) {
      req.rawBody = buf.toString('utf8');
    }
  }
}));

// Normal body parsing for other routes
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging and tracking middleware
app.use(requestLogger);
app.use((req, res, next) => {
  req.id = Math.random().toString(36).substr(2, 9);
  next();
});

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      database: 'connected',
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      error: error.message
    });
  }
});

// API routes
app.use('/api/payments', paymentRoutes);
app.use('/api/webhooks', webhookRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Payment API Server',
    version: '1.0.0',
    endpoints: {
      payments: '/api/payments',
      webhooks: '/api/webhooks',
      health: '/health'
    },
    documentation: {
      pay: 'POST /api/payments/pay',
      webhook: 'POST /api/webhooks',
      payment_details: 'GET /api/payments/:id',
      payment_stats: 'GET /api/payments/stats',
      webhook_status: 'GET /api/webhooks/status'
    }
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found',
    path: req.originalUrl
  });
});

// Error middleware
app.use(errorHandler);

// Start server
const server = app.listen(PORT, () => {
  console.log(`🚀 Payment API server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`💳 Payment endpoint: http://localhost:${PORT}/api/payments/pay`);
  console.log(`🔗 Webhook endpoint: http://localhost:${PORT}/api/webhooks`);
  ReconciliationJob.start();
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    pool.end();
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
    pool.end();
  });
});

module.exports = app;
