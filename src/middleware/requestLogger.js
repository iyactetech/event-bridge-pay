const morgan = require('morgan');

// Custom token for request ID
morgan.token('id', (req) => req.id);

// Custom format
const format = ':id :method :url :status :res[content-length] - :response-time ms';

const requestLogger = morgan(format, {
  skip: (req, res) => {
    // Skip logging for health checks
    return req.url === '/health';
  }
});

module.exports = requestLogger;