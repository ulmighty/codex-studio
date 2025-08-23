export function mark(name: string): void {
  performance.mark(name);
}

export function measure(name: string, start: string, end: string): number {
  performance.measure(name, start, end);
  const entry = performance.getEntriesByName(name).pop();
  return entry ? entry.duration : 0;
}
