export async function runWebGPU(input: Float32Array): Promise<Float32Array> {
  if (!('gpu' in navigator)) {
    throw new Error('WebGPU not supported');
  }
  return input;
}
