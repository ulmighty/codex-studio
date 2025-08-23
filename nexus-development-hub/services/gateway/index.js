const express = require('express');

const app = express();
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/', (req, res) => {
  res.json({ message: 'Gateway service' });
});

const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`Gateway service listening on port ${PORT}`);
});
