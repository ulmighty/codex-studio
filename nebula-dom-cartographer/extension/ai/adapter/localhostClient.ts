const ALLOW_NETWORK_TOKEN = '@allow-network';

function normaliseAnnotationValue(value: unknown): string[] {
  if (!value) return [];
  if (Array.isArray(value)) {
    return value.flatMap(normaliseAnnotationValue);
  }
  if (typeof value === 'string') {
    return value
      .split(/[,\s]+/)
      .map((entry) => entry.trim())
      .filter(Boolean);
  }
  if (typeof value === 'object') {
    return Object.values(value).flatMap(normaliseAnnotationValue);
  }
  return [];
}

function hasAllowNetworkAnnotation(payload: unknown): boolean {
  if (typeof payload === 'string') {
    return payload.includes(ALLOW_NETWORK_TOKEN);
  }
  if (!payload || typeof payload !== 'object') {
    return false;
  }

  const record = payload as Record<string, unknown>;
  if (record.allowNetwork === true) {
    return true;
  }

  const candidates: unknown[] = [
    record.annotations,
    record.flags,
    record.tags,
    record.directives,
    record.metadata &&
      typeof record.metadata === 'object' &&
      (record.metadata as Record<string, unknown>).annotations,
  ].filter(Boolean);

  return normaliseAnnotationValue(candidates).includes(ALLOW_NETWORK_TOKEN);
}

export async function inferLocal(payload: unknown): Promise<unknown> {
  if (!hasAllowNetworkAnnotation(payload)) {
    throw new Error(
      'Network egress blocked: add @allow-network annotation to opt in.',
    );
  }

  const res = await fetch('http://localhost:8080/infer', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return res.json();
}

export { hasAllowNetworkAnnotation };
