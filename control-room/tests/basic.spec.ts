import fs from 'fs';
import path from 'path';
import { appendCommand, safeJoin, sseFormat } from '../src/lib/fs';

const BASE = path.resolve('/workspace/.nexusforge');

describe('safeJoin', () => {
  beforeAll(() => {
    fs.mkdirSync(BASE, { recursive: true });
  });

  test('rejects directory traversal', () => {
    expect(() => safeJoin('../etc/passwd')).toThrow('bad path');
  });

  test('rejects symlink escape', () => {
    const escapeTarget = path.resolve('/tmp/safejoin-escape');
    const link = path.join(BASE, 'escape-link');
    fs.mkdirSync(escapeTarget, { recursive: true });
    try {
      if (fs.existsSync(link)) fs.unlinkSync(link);
      fs.symlinkSync(escapeTarget, link);
      expect(() => safeJoin('escape-link', 'notes.txt')).toThrow('bad path');
    } finally {
      if (fs.existsSync(link)) fs.unlinkSync(link);
      fs.rmSync(escapeTarget, { recursive: true, force: true });
    }
  });
});

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
