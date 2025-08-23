import { onMessage, sendMessage } from '../shared/messageBus';

onMessage('ping', (payload) => {
  console.log('service worker received', payload);
  sendMessage('pong', payload);
});
