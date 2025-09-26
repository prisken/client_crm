const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// WhatsApp Business API Configuration
const WHATSAPP_API_URL = process.env.WHATSAPP_API_URL || 'https://graph.facebook.com/v18.0';
const WHATSAPP_PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;
const WHATSAPP_ACCESS_TOKEN = process.env.WHATSAPP_ACCESS_TOKEN;
const WHATSAPP_VERIFY_TOKEN = process.env.WHATSAPP_VERIFY_TOKEN;

// JWT Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
};

// WhatsApp message templates (in production, these would be stored in a database)
const messageTemplates = {
    'welcome': {
        name: 'welcome',
        language: 'en',
        status: 'APPROVED',
        category: 'UTILITY',
        components: [
            {
                type: 'BODY',
                text: 'Hello {{firstName}}, welcome to our insurance services!'
            }
        ]
    },
    'follow_up': {
        name: 'follow_up',
        language: 'en',
        status: 'APPROVED',
        category: 'UTILITY',
        components: [
            {
                type: 'BODY',
                text: 'Hi {{firstName}}, this is a follow-up regarding your {{productType}} insurance quote. Please let us know if you have any questions.'
            }
        ]
    },
    'quote_ready': {
        name: 'quote_ready',
        language: 'en',
        status: 'APPROVED',
        category: 'UTILITY',
        components: [
            {
                type: 'BODY',
                text: 'Hello {{firstName}}, your {{productType}} insurance quote is ready! Premium: ${{premium}}. Please contact us to proceed.'
            }
        ]
    }
};

// Routes

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Send WhatsApp message
app.post('/whatsapp/send', verifyToken, async (req, res) => {
    try {
        const { clientId, templateId, variables } = req.body;

        if (!clientId || !templateId) {
            return res.status(400).json({ error: 'clientId and templateId are required' });
        }

        // Get client phone number (in production, this would come from your database)
        const clientPhone = await getClientPhoneNumber(clientId);
        if (!clientPhone) {
            return res.status(404).json({ error: 'Client not found' });
        }

        // Get template
        const template = messageTemplates[templateId];
        if (!template) {
            return res.status(404).json({ error: 'Template not found' });
        }

        // Prepare message payload for WhatsApp API
        const messagePayload = {
            messaging_product: 'whatsapp',
            to: clientPhone,
            type: 'template',
            template: {
                name: template.name,
                language: { code: template.language },
                components: template.components.map(component => {
                    if (component.type === 'BODY') {
                        return {
                            type: 'body',
                            parameters: Object.keys(variables || {}).map(key => ({
                                type: 'text',
                                text: variables[key]
                            }))
                        };
                    }
                    return component;
                })
            }
        };

        // Send to WhatsApp Business API
        const response = await axios.post(
            `${WHATSAPP_API_URL}/${WHATSAPP_PHONE_NUMBER_ID}/messages`,
            messagePayload,
            {
                headers: {
                    'Authorization': `Bearer ${WHATSAPP_ACCESS_TOKEN}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        // Return success response
        res.json({
            messageId: response.data.messages[0].id,
            status: 'sent',
            sentAt: new Date().toISOString()
        });

    } catch (error) {
        console.error('Error sending WhatsApp message:', error);
        
        if (error.response) {
            res.status(error.response.status).json({
                error: 'WhatsApp API error',
                details: error.response.data
            });
        } else {
            res.status(500).json({
                error: 'Internal server error',
                message: error.message
            });
        }
    }
});

// Get message status
app.get('/whatsapp/status/:messageId', verifyToken, async (req, res) => {
    try {
        const { messageId } = req.params;

        // In production, you would query the WhatsApp Business API for message status
        // For now, we'll return a mock response
        res.json({
            status: 'delivered',
            deliveredAt: new Date().toISOString(),
            readAt: null
        });

    } catch (error) {
        console.error('Error getting message status:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message
        });
    }
});

// Webhook for WhatsApp status updates
app.post('/whatsapp/webhook', (req, res) => {
    const { body } = req;

    // Verify webhook
    if (req.query['hub.verify_token'] === WHATSAPP_VERIFY_TOKEN) {
        return res.send(req.query['hub.challenge']);
    }

    // Process webhook data
    if (body.object === 'whatsapp_business_account') {
        body.entry?.forEach(entry => {
            entry.changes?.forEach(change => {
                if (change.field === 'messages') {
                    const messages = change.value.messages;
                    const statuses = change.value.statuses;

                    // Process message statuses
                    statuses?.forEach(status => {
                        console.log(`Message ${status.id} status: ${status.status}`);
                        // Update message status in your database
                        updateMessageStatus(status.id, status.status, status.timestamp);
                    });

                    // Process incoming messages
                    messages?.forEach(message => {
                        console.log(`Received message from ${message.from}: ${message.text?.body}`);
                        // Handle incoming messages (auto-replies, etc.)
                    });
                }
            });
        });
    }

    res.status(200).send('OK');
});

// Get message templates
app.get('/whatsapp/templates', verifyToken, async (req, res) => {
    try {
        // In production, this would fetch from WhatsApp Business API
        res.json({
            data: Object.values(messageTemplates)
        });
    } catch (error) {
        console.error('Error fetching templates:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message
        });
    }
});

// Helper functions
async function getClientPhoneNumber(clientId) {
    // In production, this would query your database
    // For now, return a mock phone number
    return '+1234567890';
}

function updateMessageStatus(messageId, status, timestamp) {
    // In production, this would update your database
    console.log(`Updating message ${messageId} to status ${status} at ${timestamp}`);
}

// Error handling middleware
app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).json({
        error: 'Internal server error',
        message: error.message
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`WhatsApp Phone Number ID: ${WHATSAPP_PHONE_NUMBER_ID}`);
    console.log(`Webhook URL: https://your-domain.com/whatsapp/webhook`);
});

module.exports = app;


