export function consensus(scores: number[][]): number[] {
  const len = scores[0]?.length ?? 0;
  return Array.from({ length: len }, (_, i) => {
    let sum = 0;
    for (const s of scores) sum += s[i] ?? 0;
    return sum / scores.length;
  });
}
