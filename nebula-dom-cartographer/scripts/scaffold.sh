#!/usr/bin/env bash
set -e
BASE=$(dirname "$0")/..
mkdir -p "$BASE/extension/sw" "$BASE/extension/content/workers" "$BASE/extension/ui/popup" "$BASE/extension/ui/options" \
  "$BASE/extension/shared" "$BASE/extension/ai/webgpu" "$BASE/extension/ai/webgl" "$BASE/extension/ai/cpu" \
  "$BASE/extension/ai/adapter" "$BASE/extension/ai/selector" "$BASE/extension/perf" "$BASE/extension/memory" \
  "$BASE/extension/config" "$BASE/extension/abtest" "$BASE/extension/export/templates" \
  "$BASE/tests/unit" "$BASE/tests/e2e" "$BASE/tests/perf" "$BASE/benchmarks" "$BASE/.github/workflows"
cat > "$BASE/extension/manifest.json" <<'JSON'
{
  "manifest_version": 3,
  "name": "Nebula DOM Cartographer",
  "version": "0.1.0",
  "description": "GPU-accelerated DOM analysis and selector generation",
  "permissions": ["activeTab", "scripting", "storage"],
  "background": { "service_worker": "sw/service-worker.js" },
  "action": { "default_popup": "ui/popup/index.html" },
  "options_page": "ui/options/index.html",
  "host_permissions": ["<all_urls>"],
  "web_accessible_resources": [
    { "resources": ["export/templates/*.hbs"], "matches": ["<all_urls>"] }
  ]
}
JSON
cat > "$BASE/extension/sw/service-worker.ts" <<'TS'
import { onMessage, sendMessage } from '../shared/messageBus';

onMessage('ping', (payload) => {
  console.log('service worker received', payload);
  sendMessage('pong', payload);
});
TS

cat > "$BASE/extension/shared/messageBus.ts" <<'TS'
import { EventEmitter } from 'events';
import { Message } from './types';

const emitter = new EventEmitter();

export function sendMessage<T>(type: string, payload: T): void {
  const msg: Message<T> = { type, payload };
  if (typeof chrome !== 'undefined' && chrome.runtime?.sendMessage) {
    chrome.runtime.sendMessage(msg);
  } else {
    setTimeout(() => emitter.emit(type, payload), 0);
  }
}

export function onMessage<T>(type: string, handler: (payload: T) => void): void {
  if (typeof chrome !== 'undefined' && chrome.runtime?.onMessage) {
    chrome.runtime.onMessage.addListener((msg: Message<T>) => {
      if (msg.type === type) handler(msg.payload);
    });
  } else {
    emitter.on(type, handler);
  }
}
TS
