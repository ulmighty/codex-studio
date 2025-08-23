import { onMessage, sendMessage } from '../../extension/shared/messageBus';

test('message bus delivers payload', (done) => {
  onMessage<number>('ping', (payload) => {
    expect(payload).toBe(42);
    done();
  });
  sendMessage('ping', 42);
});
