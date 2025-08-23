import { Worker } from 'worker_threads';

const sizes = [1, 4, 16, 64];
for (const size of sizes) {
  const workers: Worker[] = [];
  for (let i = 0; i < size; i += 1) {
    workers.push(new Worker(``, { eval: true }));
  }
  console.log(`spawned ${size} workers`);
  workers.forEach((w) => w.terminate());
}
