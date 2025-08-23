export async function inferLocal(payload: unknown): Promise<unknown> {
  const res = await fetch('http://localhost:8080/infer', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return res.json();
}
