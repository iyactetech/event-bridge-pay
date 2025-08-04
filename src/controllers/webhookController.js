// WebhookController.js
const Webhook = require('../models/Webhook');
const Payment = require('../models/Payment');
const crypto = require('crypto');

class WebhookController {
  static async handleWebhook(req, res) {
    try {
      const signature = req.headers['x-webhook-signature'];
      const rawBody = req.rawBody;

      if (!signature || !rawBody) {
        return res.status(401).json({
          success: false,
          error: 'Webhook signature or raw body missing'
        });
      }

      const expectedSignature = crypto
        .createHmac('sha256', process.env.WEBHOOK_SECRET)
        .update(rawBody)
        .digest('hex');

      console.log('--- Signature Debug ---');
      console.log('Raw Body:', rawBody);
      console.log('Expected Signature:', expectedSignature);
      console.log('Received Signature:', signature);
      console.log('Match:', signature === expectedSignature);

      if (signature !== expectedSignature) {
        return res.status(401).json({
          success: false,
          error: 'Invalid webhook signature'
        });
      }

      const { event_type, payment_id, provider, data } = req.body;

      const webhook = await Webhook.create({
        payment_id,
        event_type,
        provider: provider || 'unknown',
        payload: data
      });

      await WebhookController.processWebhookEvent(webhook);

      res.status(200).json({
        success: true,
        message: 'Webhook received and processed',
        webhook_id: webhook.id
      });
    } catch (error) {
      console.error('Webhook processing error:', error);
      res.status(500).json({
        success: false,
        error: 'Webhook processing failed'
      });
    }
  }

  static async processWebhookEvent(webhook) {
    try {
      const { event_type, payment_id, payload } = webhook;

      switch (event_type) {
        case 'payment.completed':
          await Payment.updateStatus(payment_id, 'completed', payload.reference);
          break;
        case 'payment.failed':
          await Payment.updateStatus(payment_id, 'failed', null);
          break;
        case 'payment.refunded':
          await Payment.updateStatus(payment_id, 'refunded', payload.refund_reference);
          break;
        default:
          console.log(`Unhandled webhook event type: ${event_type}`);
      }

      await Webhook.markAsProcessed(webhook.id);
    } catch (error) {
      console.error('Webhook event processing error:', error);
      throw error;
    }
  }

  static async getWebhookStatus(req, res) {
    try {
      const unprocessedWebhooks = await Webhook.findUnprocessed();
      res.json({
        success: true,
        data: {
          unprocessed_count: unprocessedWebhooks.length,
          webhooks: unprocessedWebhooks
        }
      });
    } catch (error) {
      console.error('Get webhook status error:', error);
      res.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }
}

module.exports = WebhookController;

