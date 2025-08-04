const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  
  // Default error
  let error = {
    success: false,
    message: err.message || 'Internal Server Error',
    status: err.status || 500
  };
  
  // Database connection errors
  if (err.code === 'ECONNREFUSED') {
    error.message = 'Database connection failed';
    error.status = 503;
  }
  
  // Validation errors
  if (err.name === 'ValidationError') {
    error.message = 'Validation Error';
    error.status = 400;
    error.details = err.details;
  }
  
  // PostgreSQL errors
  if (err.code && err.code.startsWith('23')) {
    error.message = 'Database constraint violation';
    error.status = 400;
  }
  
  res.status(error.status).json(error);
};

module.exports = errorHandler;