export function runWebGL(input: Float32Array): Float32Array {
  const out = new Float32Array(input.length);
  out.set(input);
  return out;
}
