export function toJSON(data: unknown): string {
  return JSON.stringify(data, null, 2);
}
