const PaymentService = require('../services/paymentService');
const Payment = require('../models/Payment');

class PaymentController {
  static async processPayment(req, res) {
    try {
      const { amount, currency, customer_id, description, metadata } = req.body;
      
      // Validate required fields
      if (!amount || !customer_id) {
        return res.status(400).json({
          success: false,
          error: 'Amount and customer_id are required'
        });
      }
      
      // Validate amount
      if (amount <= 0) {
        return res.status(400).json({
          success: false,
          error: 'Amount must be greater than 0'
        });
      }
      
      const paymentData = {
        amount: parseFloat(amount),
        currency: currency || 'USD',
        customer_id,
        description,
        metadata
      };
      
      const result = await PaymentService.processPayment(paymentData);
      
      res.status(201).json({
        success: true,
        message: 'Payment processed successfully',
        data: result
      });
    } catch (error) {
      console.error('Payment processing error:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: error.message
      });
    }
  }

  static async getPayment(req, res) {
    try {
      const { id } = req.params;
      
      const payment = await Payment.findById(id);
      
      if (!payment) {
        return res.status(404).json({
          success: false,
          error: 'Payment not found'
        });
      }
      
      res.json({
        success: true,
        data: payment
      });
    } catch (error) {
      console.error('Get payment error:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }

  static async getPaymentStats(req, res) {
    try {
      const stats = await Payment.getPaymentStats();
      
      res.json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Get payment stats error:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }
}

module.exports = PaymentController;