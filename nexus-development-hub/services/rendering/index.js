const express = require('express');

const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/render', (req, res) => {
  // Placeholder rendering implementation
  res.json({ svg: '<svg><!-- rendering placeholder --></svg>' });
});

const PORT = process.env.PORT || 8003;
app.listen(PORT, () => {
  console.log(`Rendering service listening on port ${PORT}`);
});
