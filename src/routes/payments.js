const express = require('express');
const PaymentController = require('../controllers/paymentController');

const router = express.Router();

// GET /api/payments/stats - Get payment statistics
router.get('/stats', PaymentController.getPaymentStats);

// POST /api/payments/pay - Process a payment
router.post('/pay', PaymentController.processPayment);

// GET /api/payments/:id - Get payment details
router.get('/:id', PaymentController.getPayment);


module.exports = router;