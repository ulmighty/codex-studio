const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

io.on('connection', () => {
  console.log('Client connected');
});

const PORT = process.env.PORT || 8001;
server.listen(PORT, () => {
  console.log(`Realtime service listening on port ${PORT}`);
});
