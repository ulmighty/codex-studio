export function toPDF(text: string): ArrayBuffer {
  const encoder = new TextEncoder();
  return encoder.encode(text).buffer;
}
