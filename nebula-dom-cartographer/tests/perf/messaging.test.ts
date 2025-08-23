import { onMessage, sendMessage } from '../../extension/shared/messageBus';

test('message bus handles 100 messages', (done) => {
  let count = 0;
  const total = 100;
  onMessage('pong', () => {
    count += 1;
    if (count === total) done();
  });
  for (let i = 0; i < total; i += 1) {
    sendMessage('pong', i);
  }
});
