import fs from 'fs';
import path from 'path';

const BASE = path.resolve('/workspace/.nexusforge');

function assertWithinBase(target: string) {
  const relative = path.relative(BASE, target);
  if (relative && (relative.startsWith('..') || path.isAbsolute(relative))) {
    throw new Error('bad path');
  }
}

function assertNoSymlinkEscape(target: string) {
  const relative = path.relative(BASE, target);
  if (!relative) return;
  const segments = relative.split(path.sep).filter(Boolean);
  let current = BASE;
  for (const segment of segments) {
    current = path.join(current, segment);
    if (fs.existsSync(current)) {
      const real = fs.realpathSync(current);
      assertWithinBase(real);
    }
  }
}

function enforcePathSafety(target: string) {
  assertWithinBase(target);
  assertNoSymlinkEscape(target);
}

export function safeJoin(...segs: string[]) {
  const resolved = path.resolve(BASE, ...segs);
  enforcePathSafety(resolved);
  return resolved;
}

export async function readText(rel: string) {
  const file = safeJoin(rel);
  await fs.promises.mkdir(path.dirname(file), { recursive: true });
  if (!fs.existsSync(file)) await fs.promises.writeFile(file, '');
  return fs.promises.readFile(file, 'utf8');
}

export async function readJson(rel: string, def: any) {
  const file = safeJoin(rel);
  await fs.promises.mkdir(path.dirname(file), { recursive: true });
  if (!fs.existsSync(file)) await fs.promises.writeFile(file, JSON.stringify(def, null, 2));
  try {
    return JSON.parse(await fs.promises.readFile(file, 'utf8'));
  } catch {
    return def;
  }
}

export async function listDir(rel: string) {
  const dir = safeJoin(rel);
  await fs.promises.mkdir(dir, { recursive: true });
  return fs.promises.readdir(dir);
}

export async function appendCommand(obj: any) {
  const file = safeJoin('commands', 'queue.jsonl');
  await fs.promises.mkdir(path.dirname(file), { recursive: true });
  await fs.promises.appendFile(file, JSON.stringify(obj) + '\n');
}

export function sseFormat(line: string) {
  return `data: ${line}\n\n`;
}

export function tailStream(rel: string) {
  const file = safeJoin(rel);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (!fs.existsSync(file)) fs.writeFileSync(file, '');
  let watcher: fs.FSWatcher;
  let timer: NodeJS.Timeout;
  let pos = 0;
  const encoder = new TextEncoder();
  return new ReadableStream<Uint8Array>({
    start(controller) {
      const send = (line: string) => controller.enqueue(encoder.encode(sseFormat(line)));
      const readNew = () => {
        try {
          const real = fs.realpathSync(file);
          enforcePathSafety(real);
        } catch (error) {
          controller.error(error);
          watcher?.close();
          clearInterval(timer);
          return;
        }
        fs.readFile(file, 'utf8', (err, data) => {
          if (err) return;
          const slice = data.slice(pos);
          pos = data.length;
          slice.split(/\n/).filter(Boolean).forEach(send);
        });
      };
      readNew();
      watcher = fs.watch(file, readNew);
      timer = setInterval(readNew, 1000);
    },
    cancel() {
      watcher?.close();
      clearInterval(timer);
    }
  });
}
