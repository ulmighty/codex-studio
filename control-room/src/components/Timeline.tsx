'use client';

import { useEffect, useState } from 'react';
import type { TimelineSegment } from '@/lib/api';
import { getTimelineSegments } from '@/lib/api';

export function Timeline() {
  const [segments, setSegments] = useState<TimelineSegment[]>([]);

  useEffect(() => {
    let active = true;
    getTimelineSegments().then((data) => {
      if (!active) return;
      setSegments(data);
    });
    return () => {
      active = false;
    };
  }, []);

  return (
    <section className="h-full rounded-2xl border border-gray-800 bg-gray-900/70 p-6 shadow-xl shadow-black/20">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-50">Scene Timeline</h2>
          <p className="text-sm text-gray-400">Segmented detections with tracked entities.</p>
        </div>
        <span className="text-xs text-gray-500">{segments.length} segments</span>
      </header>
      <ol className="space-y-6">
        {segments.map((segment, index) => (
          <li key={segment.id} className="relative pl-8">
            <span className="absolute left-0 top-1 flex h-5 w-5 items-center justify-center rounded-full border border-emerald-400/60 bg-emerald-500/10 text-xs text-emerald-300">
              {index + 1}
            </span>
            <div className="flex flex-col gap-3 rounded-xl border border-gray-800 bg-gray-950/60 p-4">
              <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-gray-400">
                <span className="rounded bg-gray-800/70 px-2 py-0.5 font-medium text-gray-200">
                  {segment.start} - {segment.end}
                </span>
                <span className="text-xs uppercase tracking-wide text-emerald-300">{segment.entities.length} detections</span>
              </div>
              <p className="text-sm text-gray-300">{segment.summary}</p>
              <div className="flex flex-wrap gap-2">
                {segment.entities.map((entity) => (
                  <span
                    key={entity.id}
                    className="flex items-center gap-2 rounded-full border border-gray-700 bg-gray-900/80 px-3 py-1 text-xs text-gray-300"
                  >
                    <span>{entity.icon ?? getFallbackIcon(entity.type)}</span>
                    <span className="font-medium text-gray-200">{entity.name}</span>
                    <span className="text-[10px] uppercase tracking-wide text-gray-500">{entity.type}</span>
                  </span>
                ))}
              </div>
            </div>
          </li>
        ))}
        {segments.length === 0 ? (
          <li className="rounded-xl border border-gray-800 bg-gray-950/60 p-6 text-sm text-gray-400">
            Awaiting timeline data…
          </li>
        ) : null}
      </ol>
    </section>
  );
}

function getFallbackIcon(type: string) {
  switch (type) {
    case 'person':
      return '👤';
    case 'vehicle':
      return '🚗';
    default:
      return '🔍';
  }
}
