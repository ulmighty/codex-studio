export async function gpuScore(tags: string[]): Promise<Float32Array> {
  const scores = new Float32Array(tags.length);
  scores.fill(1);
  return scores;
}
