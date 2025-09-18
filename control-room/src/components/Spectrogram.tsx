'use client';

import { useEffect, useState } from 'react';
import type { SpectrogramTrack } from '@/lib/api';
import { getSpectrograms } from '@/lib/api';

const SEVERITY_COLORS: Record<string, string> = {
  low: 'bg-emerald-500/80 border-emerald-400/80 text-emerald-950',
  medium: 'bg-amber-400/90 border-amber-300/90 text-amber-950',
  high: 'bg-rose-500/90 border-rose-400/90 text-rose-950'
};

export function Spectrogram() {
  const [tracks, setTracks] = useState<SpectrogramTrack[]>([]);

  useEffect(() => {
    let active = true;
    getSpectrograms().then((data) => {
      if (!active) return;
      setTracks(data);
    });
    return () => {
      active = false;
    };
  }, []);

  return (
    <section className="rounded-2xl border border-gray-800 bg-gray-900/70 p-6 shadow-xl shadow-black/20">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-50">Spectrogram Monitor</h2>
          <p className="text-sm text-gray-400">Acoustic and thermal overlays with flagged anomalies.</p>
        </div>
        <span className="text-xs text-gray-500">{tracks.length} tracks</span>
      </header>
      <div className="grid grid-cols-1 gap-4">
        {tracks.map((track) => (
          <article key={track.id} className="overflow-hidden rounded-xl border border-gray-800 bg-gray-950/60">
            <div className="flex items-center justify-between border-b border-gray-800 px-4 py-3 text-sm text-gray-300">
              <div>
                <h3 className="font-semibold text-gray-100">{track.label}</h3>
                <p className="text-xs text-gray-500">Duration {track.durationSeconds}s</p>
              </div>
              <span className="rounded-full border border-gray-800 bg-gray-900 px-3 py-1 text-xs text-gray-400">
                {track.anomalies.length} anomalies
              </span>
            </div>
            <div className="relative">
              <img src={track.imageUrl} alt={track.label} className="h-56 w-full object-cover" />
              {track.anomalies.map((anomaly) => (
                <span
                  key={anomaly.id}
                  className={`absolute flex -translate-x-1/2 translate-y-1/2 items-center gap-2 rounded-full border px-2 py-1 text-[11px] font-semibold shadow-lg shadow-black/30 ${
                    SEVERITY_COLORS[anomaly.severity]
                  }`}
                  style={{ left: `${anomaly.time * 100}%`, bottom: `${anomaly.frequency * 100}%` }}
                >
                  <span className="h-2 w-2 rounded-full bg-current opacity-80" />
                  {anomaly.label}
                </span>
              ))}
            </div>
          </article>
        ))}
        {tracks.length === 0 ? (
          <div className="rounded-xl border border-gray-800 bg-gray-950/60 p-6 text-sm text-gray-400">
            No spectrogram feeds connected.
          </div>
        ) : null}
      </div>
    </section>
  );
}
