export class MemoryManager {
  private pool: ArrayBuffer[] = [];

  acquire(size: number): ArrayBuffer {
    const buf = this.pool.pop();
    return buf && buf.byteLength >= size ? buf : new ArrayBuffer(size);
  }

  release(buf: ArrayBuffer): void {
    this.pool.push(buf);
  }
}
