export function toMarkdown(lines: string[]): string {
  return lines.map((l) => `- ${l}`).join('\n');
}
