const express = require('express');
const router = express.Router();
const axios = require('axios');

router.post('/send-telegram', async (req, res) => {
  console.log('📨 Received request to send Telegram message');
  try {
    const { chat_id, message } = req.body;
    if (!chat_id || !message) {
      console.log('⚠️ Missing chat_id or message');
      return res.status(400).send({ error: 'Missing chat_id or message' });
    }

    const telegramResponse = await axios.post(
      `https://api.telegram.org/bot7419597687:AAEmD5j85t26-cMAekacceIPiV86z1SdRH4/sendMessage`,
      {
        chat_id,
        text: message,
      }
    );

    console.log('✅ Telegram API responded:', telegramResponse.data);
    res.status(200).send(telegramResponse.data);
  } catch (error) {
    console.error('❌ Telegram send failed:', error.message);
    res.status(500).send({ error: error.message });
  }
});

module.exports = router;
