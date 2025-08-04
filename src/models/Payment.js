const pool = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Payment {
  static async create(paymentData) {
    const {
      amount,
      currency = 'USD',
      customer_id,
      description,
      metadata = {}
    } = paymentData;

    const id = uuidv4();
    const query = `
      INSERT INTO payments (id, amount, currency, customer_id, description, metadata)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `;
    
    const values = [id, amount, currency, customer_id, description, JSON.stringify(metadata)];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to create payment: ${error.message}`);
    }
  }

  static async findById(id) {
    const query = 'SELECT * FROM payments WHERE id = $1';
    
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to find payment: ${error.message}`);
    }
  }

  static async updateStatus(id, status, providerReference = null) {
    const query = `
      UPDATE payments 
      SET status = $1, provider_reference = $2, updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [status, providerReference, id]);
      return result.rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to update payment status: ${error.message}`);
    }
  }

  static async findPendingPayments() {
    const query = `
      SELECT * FROM payments 
      WHERE status = 'pending' 
      ORDER BY created_at ASC
    `;
    
    try {
      const result = await pool.query(query);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to find pending payments: ${error.message}`);
    }
  }

  static async getPaymentStats() {
    const query = `
      SELECT 
        status,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM payments 
      GROUP BY status
    `;
    
    try {
      const result = await pool.query(query);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get payment stats: ${error.message}`);
    }
  }
}

module.exports = Payment;