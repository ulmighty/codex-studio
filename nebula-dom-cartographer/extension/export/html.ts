export function toHTML(lines: string[]): string {
  return `<ul>${lines.map((l) => `<li>${l}</li>`).join('')}</ul>`;
}
