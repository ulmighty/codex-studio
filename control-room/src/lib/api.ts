export type HealthStatus = {
  status: 'ok' | 'degraded' | 'down' | 'unknown';
  message?: string;
  checkedAt: string;
};

export type FaceAppearance = {
  id: string;
  timecode: string;
  context: string;
  thumbnail?: string;
};

export type FaceCluster = {
  id: string;
  label: string;
  confidence: number;
  lastSeen: string;
  appearances: FaceAppearance[];
};

export type TimelineEntity = {
  id: string;
  type: 'person' | 'object' | 'vehicle';
  name: string;
  icon?: string;
};

export type TimelineSegment = {
  id: string;
  start: string;
  end: string;
  summary: string;
  entities: TimelineEntity[];
};

export type SpectrogramAnomaly = {
  id: string;
  label: string;
  severity: 'low' | 'medium' | 'high';
  /**
   * Position on the horizontal axis expressed as a ratio (0 – 1).
   */
  time: number;
  /**
   * Position on the vertical axis expressed as a ratio (0 – 1).
   */
  frequency: number;
};

export type SpectrogramTrack = {
  id: string;
  label: string;
  durationSeconds: number;
  imageUrl: string;
  anomalies: SpectrogramAnomaly[];
};

export type PrivacySettings = {
  privacyBlur: boolean;
  recognitionThreshold: number;
  anomalyThreshold: number;
};

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? '';

async function safeFetch<T>(path: string, init?: RequestInit): Promise<T | null> {
  try {
    const response = await fetch(`${API_BASE}${path}`, {
      ...init,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        ...(init?.headers ?? {})
      }
    });

    if (!response.ok) {
      throw new Error(`Request failed with status ${response.status}`);
    }

    return (await response.json()) as T;
  } catch (error) {
    console.warn(`[api] request to ${path} failed`, error);
    return null;
  }
}

export async function getHealthStatus(): Promise<HealthStatus> {
  const data = await safeFetch<HealthStatus>('/health');
  if (data) {
    return data;
  }
  return {
    status: 'unknown',
    message: 'No connection to backend',
    checkedAt: new Date().toISOString()
  };
}

export async function getFaceClusters(): Promise<FaceCluster[]> {
  const data = await safeFetch<FaceCluster[]>('/api/face-clusters');
  return data ?? fallbackFaceClusters;
}

export async function getTimelineSegments(): Promise<TimelineSegment[]> {
  const data = await safeFetch<TimelineSegment[]>('/api/timeline');
  return data ?? fallbackTimelineSegments;
}

export async function getTranscript(): Promise<string> {
  const data = await safeFetch<{ transcript: string }>('/api/transcript');
  if (data?.transcript) {
    return data.transcript;
  }
  return fallbackTranscript;
}

export async function getSpectrograms(): Promise<SpectrogramTrack[]> {
  const data = await safeFetch<SpectrogramTrack[]>('/api/spectrograms');
  return data ?? fallbackSpectrograms;
}

export async function getPrivacySettings(): Promise<PrivacySettings> {
  const data = await safeFetch<PrivacySettings>('/api/settings');
  return data ?? fallbackPrivacySettings;
}

export async function updatePrivacySettings(next: PrivacySettings): Promise<PrivacySettings> {
  const data = await safeFetch<PrivacySettings>('/api/settings', {
    method: 'POST',
    body: JSON.stringify(next)
  });
  return data ?? next;
}

const fallbackFaceClusters: FaceCluster[] = [
  {
    id: 'cluster-01',
    label: 'Engineer – Elena Ruiz',
    confidence: 0.92,
    lastSeen: '2023-08-01T14:22:00Z',
    appearances: [
      {
        id: 'appearance-01a',
        timecode: '00:01:12',
        context: 'Manufacturing floor, camera 3',
        thumbnail:
          'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect width="96" height="96" fill="%2371c7ec"/><text x="50%" y="55%" font-size="32" fill="%23000" text-anchor="middle">ER</text></svg>'
      },
      {
        id: 'appearance-01b',
        timecode: '00:17:45',
        context: 'Loading dock, camera 6',
        thumbnail:
          'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect width="96" height="96" fill="%2326639b"/><text x="50%" y="55%" font-size="32" fill="%23fff" text-anchor="middle">ER</text></svg>'
      },
      {
        id: 'appearance-01c',
        timecode: '00:24:09',
        context: 'Quality lab entrance',
        thumbnail:
          'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96"><rect width="96" height="96" fill="%237881f7"/><text x="50%" y="55%" font-size="32" fill="%23000" text-anchor="middle">ER</text></svg>'
      }
    ]
  },
  {
    id: 'cluster-02',
    label: 'Visitor – Unknown',
    confidence: 0.61,
    lastSeen: '2023-08-01T13:58:00Z',
    appearances: [
      {
        id: 'appearance-02a',
        timecode: '00:03:31',
        context: 'Reception, camera 1'
      },
      {
        id: 'appearance-02b',
        timecode: '00:19:06',
        context: 'R&D corridor'
      }
    ]
  },
  {
    id: 'cluster-03',
    label: 'Operator – Dylan Chen',
    confidence: 0.88,
    lastSeen: '2023-08-01T14:05:00Z',
    appearances: [
      {
        id: 'appearance-03a',
        timecode: '00:06:44',
        context: 'Assembly cell 2'
      },
      {
        id: 'appearance-03b',
        timecode: '00:28:22',
        context: 'Tool crib checkout'
      }
    ]
  }
];

const fallbackTimelineSegments: TimelineSegment[] = [
  {
    id: 'segment-01',
    start: '00:00:00',
    end: '00:05:00',
    summary: 'Shift change and access checks at facility entrance.',
    entities: [
      { id: 'person-elena', type: 'person', name: 'Elena Ruiz', icon: '👩‍🔧' },
      { id: 'object-badge', type: 'object', name: 'Badge Scan', icon: '🪪' }
    ]
  },
  {
    id: 'segment-02',
    start: '00:05:00',
    end: '00:18:00',
    summary: 'Assembly cell operating nominally. Forklift route flagged briefly.',
    entities: [
      { id: 'vehicle-forklift', type: 'vehicle', name: 'Forklift A2', icon: '🚜' },
      { id: 'object-pallet', type: 'object', name: 'Pallet Stack', icon: '📦' }
    ]
  },
  {
    id: 'segment-03',
    start: '00:18:00',
    end: '00:30:00',
    summary: 'Visitor escorted through R&D corridor. Late-stage QA prep begins.',
    entities: [
      { id: 'person-visitor', type: 'person', name: 'Unknown Visitor', icon: '🕵️' },
      { id: 'person-escort', type: 'person', name: 'Security Lead', icon: '🛡️' },
      { id: 'object-prototype', type: 'object', name: 'Prototype Case', icon: '💼' }
    ]
  }
];

const fallbackTranscript = `The morning shift transferred duties to the afternoon crew while security monitored for anomalies.
Elena discussed calibration adjustments with Dylan near assembly cell two.
A visiting client toured the research corridor accompanied by security.
Quality assurance flagged a potential acoustic anomaly on line four for follow up.`;

const fallbackSpectrograms: SpectrogramTrack[] = [
  {
    id: 'track-01',
    label: 'Line 4 – Acoustic',
    durationSeconds: 180,
    imageUrl:
      'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="512" height="160"><defs><linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" style="stop-color:%2309162d;stop-opacity:1"/><stop offset="100%" style="stop-color:%233855a6;stop-opacity:1"/></linearGradient></defs><rect width="512" height="160" fill="url(%23grad1)"/><circle cx="120" cy="40" r="18" fill="%2399f6ff" opacity="0.6"/><circle cx="320" cy="80" r="26" fill="%23fcd34d" opacity="0.6"/><circle cx="420" cy="120" r="20" fill="%23f472b6" opacity="0.6"/></svg>',
    anomalies: [
      { id: 'anomaly-01', label: 'Harmonic spike', severity: 'medium', time: 0.36, frequency: 0.25 },
      { id: 'anomaly-02', label: 'Bearing resonance', severity: 'high', time: 0.62, frequency: 0.5 }
    ]
  },
  {
    id: 'track-02',
    label: 'Compressor – Thermal',
    durationSeconds: 95,
    imageUrl:
      'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="512" height="160"><defs><linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:%2322253d;stop-opacity:1"/><stop offset="100%" style="stop-color:%2342568a;stop-opacity:1"/></linearGradient></defs><rect width="512" height="160" fill="url(%23grad2)"/><rect x="40" y="50" width="60" height="60" fill="%23fca5a5" opacity="0.6"/><rect x="260" y="20" width="90" height="90" fill="%238cddf5" opacity="0.6"/><rect x="400" y="70" width="70" height="70" fill="%23fde68a" opacity="0.6"/></svg>',
    anomalies: [
      { id: 'anomaly-03', label: 'Thermal bloom', severity: 'medium', time: 0.15, frequency: 0.7 }
    ]
  }
];

const fallbackPrivacySettings: PrivacySettings = {
  privacyBlur: true,
  recognitionThreshold: 0.76,
  anomalyThreshold: 0.58
};
