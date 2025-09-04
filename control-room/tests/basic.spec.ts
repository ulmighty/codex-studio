import fs from 'fs';
import path from 'path';
import { appendCommand, sseFormat } from '../src/lib/fs';

describe('fs helpers', () => {
  test('appendCommand writes json line', async () => {
    const file = path.resolve('/workspace/.nexusforge/commands/queue.jsonl');
    if (fs.existsSync(file)) fs.unlinkSync(file);
    await appendCommand({ foo: 'bar' });
    const txt = fs.readFileSync(file, 'utf8').trim();
    expect(JSON.parse(txt).foo).toBe('bar');
  });

  test('sseFormat', () => {
    expect(sseFormat('hi')).toBe('data: hi\n\n');
  });
});
