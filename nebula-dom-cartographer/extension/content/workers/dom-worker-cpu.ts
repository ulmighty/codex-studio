export function scoreNodes(tags: string[]): number[] {
  return tags.map((t) => t.length);
}
