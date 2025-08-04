const cron = require('node-cron');
const PaymentService = require('../services/paymentService');
const pool = require('../config/database');

class ReconciliationJob {
  static start() {
    // Run reconciliation every hour at minute 0
    cron.schedule('0 * * * *', async () => {
      console.log('Starting scheduled reconciliation job...');
      await this.runReconciliation();
    });
    
    // Run reconciliation every 5 minutes for demo purposes
    cron.schedule('*/5 * * * *', async () => {
      console.log('Starting demo reconciliation job (every 5 minutes)...');
      await this.runReconciliation();
    });
    
    console.log('Reconciliation cron jobs scheduled');
  }
  
  static async runReconciliation() {
    try {
      const startTime = new Date();
      console.log(`Reconciliation started at: ${startTime.toISOString()}`);
      
      const result = await PaymentService.reconcilePayments();
      
      // Log reconciliation results
      const logQuery = `
        INSERT INTO reconciliation_logs (payments_processed, discrepancies_found, details)
        VALUES ($1, $2, $3)
        RETURNING *
      `;
      
      const logResult = await pool.query(logQuery, [
        result.payments_processed,
        result.discrepancies_found,
        JSON.stringify({
          start_time: startTime.toISOString(),
          end_time: new Date().toISOString(),
          ...result
        })
      ]);
      
      console.log('Reconciliation completed:', {
        log_id: logResult.rows[0].id,
        payments_processed: result.payments_processed,
        discrepancies_found: result.discrepancies_found
      });
      
    } catch (error) {
      console.error('Reconciliation job failed:', error);
      
      // Log failed reconciliation
      try {
        await pool.query(
          'INSERT INTO reconciliation_logs (status, details) VALUES ($1, $2)',
          ['failed', JSON.stringify({ error: error.message, timestamp: new Date().toISOString() })]
        );
      } catch (logError) {
        console.error('Failed to log reconciliation error:', logError);
      }
    }
  }
  
  static async runOnce() {
    console.log('Running one-time reconciliation...');
    await this.runReconciliation();
    process.exit(0);
  }
}

// If this file is run directly, execute reconciliation once
if (require.main === module) {
  ReconciliationJob.runOnce();
}

module.exports = ReconciliationJob;