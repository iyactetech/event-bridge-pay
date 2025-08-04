const pool = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Webhook {
  static async create(webhookData) {
    const {
      payment_id,
      event_type,
      provider,
      payload
    } = webhookData;

    const id = uuidv4();
    const query = `
      INSERT INTO webhooks (id, payment_id, event_type, provider, payload)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    
    const values = [id, payment_id, event_type, provider, JSON.stringify(payload)];
    
    try {
      const result = await pool.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to create webhook: ${error.message}`);
    }
  }

  static async markAsProcessed(id) {
    const query = `
      UPDATE webhooks 
      SET processed = TRUE 
      WHERE id = $1
      RETURNING *
    `;
    
    try {
      const result = await pool.query(query, [id]);
      return result.rows[0] || null;
    } catch (error) {
      throw new Error(`Failed to mark webhook as processed: ${error.message}`);
    }
  }

  static async findUnprocessed() {
    const query = `
      SELECT * FROM webhooks 
      WHERE processed = FALSE 
      ORDER BY created_at ASC
    `;
    
    try {
      const result = await pool.query(query);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to find unprocessed webhooks: ${error.message}`);
    }
  }
}

module.exports = Webhook;