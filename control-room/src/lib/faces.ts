export type FaceRecord = {
  id?: string | number;
  label?: string | null;
  labels?: unknown;
  annotations?: unknown;
  metadata?: Record<string, unknown> | null;
  meta?: Record<string, unknown> | null;
  whitelisted?: boolean;
  whitelist?: boolean;
  status?: string;
  confidence?: number;
  [key: string]: unknown;
};

export function coerceStrings(value: unknown): string[] {
  if (!value) return [];
  if (Array.isArray(value)) {
    return value.flatMap(coerceStrings);
  }
  if (typeof value === 'string') {
    return value
      .split(/[,\s]+/)
      .map((entry) => entry.trim())
      .filter(Boolean);
  }
  return [];
}

export function extractMetadata(face: FaceRecord): Record<string, unknown> {
  const metadata = face.metadata ?? face.meta;
  return metadata && typeof metadata === 'object' ? (metadata as Record<string, unknown>) : {};
}

export function findFaceLabel(face: FaceRecord): string | undefined {
  if (typeof face.label === 'string' && face.label.trim()) {
    return face.label.trim();
  }

  const metadata = extractMetadata(face);
  const metadataLabel = metadata.label;
  if (typeof metadataLabel === 'string' && metadataLabel.trim()) {
    return metadataLabel.trim();
  }

  const labelSources = [face.labels, metadata.labels];
  for (const source of labelSources) {
    const list = coerceStrings(source);
    if (list.length > 0) {
      return list[0];
    }
  }

  if (typeof face.id === 'string' && face.id.trim()) {
    return face.id.trim();
  }

  return undefined;
}

function hasAnnotationToken(values: string[], token: string): boolean {
  return values.some((entry) => entry === token || entry.startsWith(`${token}:`));
}

export function isFaceLabelled(face: FaceRecord | unknown): boolean {
  if (!face || typeof face !== 'object') {
    return false;
  }

  const record = face as FaceRecord;
  if (typeof record.label === 'string' && record.label.trim().length > 0) {
    return true;
  }

  if (record.whitelisted || record.whitelist) {
    return true;
  }

  if (typeof record.status === 'string' && record.status.toLowerCase().includes('label')) {
    return true;
  }

  const metadata = extractMetadata(record);
  if (metadata.whitelisted === true) {
    return true;
  }
  const metadataLabel = metadata.label;
  if (typeof metadataLabel === 'string' && metadataLabel.trim().length > 0) {
    return true;
  }

  const annotationSources = [record.annotations, metadata.annotations];
  const annotations = annotationSources.flatMap(coerceStrings);
  if (hasAnnotationToken(annotations, '@labelled')) {
    return true;
  }
  if (annotations.some((entry) => entry.toLowerCase().includes('whitelist'))) {
    return true;
  }

  const labelLists = [record.labels, metadata.labels].flatMap(coerceStrings);
  return labelLists.length > 0;
}

export function resolveFaceImage(face: FaceRecord): string | undefined {
  const metadata = extractMetadata(face);
  const candidates = [
    face.thumbnail,
    face.image,
    (face as Record<string, unknown>)['image_url'],
    face.imageUrl,
    face.dataUri,
    face.dataURI,
    face.preview,
    metadata.thumbnail,
    metadata.preview,
    metadata.image,
    metadata.dataUri,
  ];
  for (const candidate of candidates) {
    if (typeof candidate === 'string' && candidate.trim().length > 0) {
      return candidate;
    }
  }
  return undefined;
}

export function formatConfidence(value: unknown): string | undefined {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    return undefined;
  }
  const numeric = value;
  if (numeric >= 0 && numeric <= 1) {
    return `${(numeric * 100).toFixed(1)}%`;
  }
  return `${numeric.toFixed(1)}`;
}
