const Payment = require('../models/Payment');

class PaymentService {
  static async processPayment(paymentData) {
    try {
      // Create payment record
      const payment = await Payment.create(paymentData);
      
      // Simulate payment processing with provider
      const providerResponse = await this.simulateProviderCall(payment);
      
      // Update payment status based on provider response
      const updatedPayment = await Payment.updateStatus(
        payment.id,
        providerResponse.status,
        providerResponse.reference
      );
      
      return {
        success: true,
        payment: updatedPayment,
        provider_response: providerResponse
      };
    } catch (error) {
      throw new Error(`Payment processing failed: ${error.message}`);
    }
  }

  static async simulateProviderCall(payment) {
    // Simulate network delay
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Simulate random success/failure (90% success rate)
    const isSuccess = Math.random() > 0.1;
    
    if (isSuccess) {
      return {
        status: 'completed',
        reference: `PAY_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        provider_fee: payment.amount * 0.029, // 2.9% fee
        timestamp: new Date().toISOString()
      };
    } else {
      return {
        status: 'failed',
        reference: null,
        error_code: 'INSUFFICIENT_FUNDS',
        error_message: 'Payment declined by provider',
        timestamp: new Date().toISOString()
      };
    }
  }

  static async reconcilePayments() {
    try {
      const pendingPayments = await Payment.findPendingPayments();
      let processedCount = 0;
      let discrepanciesFound = 0;
      
      for (const payment of pendingPayments) {
        // Simulate checking with provider
        const providerStatus = await this.checkProviderStatus(payment.id);
        
        if (providerStatus.status !== payment.status) {
          await Payment.updateStatus(payment.id, providerStatus.status, providerStatus.reference);
          discrepanciesFound++;
        }
        
        processedCount++;
      }
      
      return {
        payments_processed: processedCount,
        discrepancies_found: discrepanciesFound,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      throw new Error(`Reconciliation failed: ${error.message}`);
    }
  }

  static async checkProviderStatus(paymentId) {
    // Simulate provider status check
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Simulate various statuses
    const statuses = ['completed', 'failed', 'pending'];
    const randomStatus = statuses[Math.floor(Math.random() * statuses.length)];
    
    return {
      status: randomStatus,
      reference: randomStatus === 'completed' ? `PAY_${Date.now()}` : null,
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = PaymentService;