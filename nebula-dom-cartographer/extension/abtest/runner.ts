export function runTest(name: string, variants: (() => void)[]): void {
  const idx = Math.floor(Math.random() * variants.length);
  variants[idx]();
  console.log(`A/B test ${name} variant ${idx}`);
}
