const express = require('express');
const WebhookController = require('../controllers/webhookController');

const router = express.Router();

// POST /api/webhooks - Handle incoming webhooks
router.post('/', WebhookController.handleWebhook);

// GET /api/webhooks/status - Get webhook processing status
router.get('/status', WebhookController.getWebhookStatus);

module.exports = router;