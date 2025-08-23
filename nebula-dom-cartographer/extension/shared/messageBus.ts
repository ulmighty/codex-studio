import { EventEmitter } from 'events';
import { Message } from './types';

const emitter = new EventEmitter();
const runtime = (globalThis as any).chrome?.runtime;

export function sendMessage<T>(type: string, payload: T): void {
  const msg: Message<T> = { type, payload };
  if (runtime?.sendMessage) {
    runtime.sendMessage(msg);
  } else {
    setTimeout(() => emitter.emit(type, payload), 0);
  }
}

export function onMessage<T>(type: string, handler: (payload: T) => void): void {
  if (runtime?.onMessage) {
    runtime.onMessage.addListener((msg: Message<T>) => {
      if (msg.type === type) handler(msg.payload);
    });
  } else {
    emitter.on(type, handler);
  }
}
