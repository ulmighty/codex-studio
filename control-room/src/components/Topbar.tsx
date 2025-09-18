'use client';

import { useEffect, useMemo, useState } from 'react';
import { getHealthStatus, type HealthStatus } from '@/lib/api';

const STATUS_COPY: Record<HealthStatus['status'], { label: string; indicator: string }> = {
  ok: { label: 'Operational', indicator: 'bg-emerald-400' },
  degraded: { label: 'Degraded', indicator: 'bg-amber-400' },
  down: { label: 'Offline', indicator: 'bg-rose-500' },
  unknown: { label: 'Unknown', indicator: 'bg-gray-500' }
};

export function Topbar() {
  const [health, setHealth] = useState<HealthStatus | null>(null);

  useEffect(() => {
    let active = true;
    const load = async () => {
      const data = await getHealthStatus();
      if (!active) return;
      setHealth(data);
    };
    load();
    const interval = window.setInterval(load, 20_000);
    return () => {
      active = false;
      window.clearInterval(interval);
    };
  }, []);

  const status = health?.status ?? 'unknown';
  const info = useMemo(() => STATUS_COPY[status], [status]);

  return (
    <header className="border-b border-gray-800 bg-gray-950/80 shadow-lg shadow-black/10 backdrop-blur">
      <div className="mx-auto flex max-w-7xl flex-col gap-4 px-6 py-5 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-emerald-400">Sentinel Control Room</p>
          <h1 className="text-xl font-semibold text-gray-100 sm:text-2xl">Video Intelligence Overview</h1>
        </div>
        <div className="flex flex-col items-start gap-2 sm:flex-row sm:items-center sm:gap-4">
          <div className="flex items-center gap-2 rounded-full border border-gray-800 bg-gray-900/80 px-3 py-1.5 text-sm text-gray-200">
            <span className={`h-2.5 w-2.5 rounded-full ${info.indicator}`} aria-hidden />
            <span>{info.label}</span>
          </div>
          <div className="text-xs text-gray-500">
            {health ? `Last check ${formatRelativeTime(health.checkedAt)}` : 'Checking system health…'}
          </div>
        </div>
      </div>
    </header>
  );
}

function formatRelativeTime(isoDate: string) {
  const now = new Date();
  const target = new Date(isoDate);
  const diff = Math.max(0, now.getTime() - target.getTime());
  const seconds = Math.floor(diff / 1000);
  if (seconds < 5) return 'just now';
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes === 1) return '1 minute ago';
  if (minutes < 60) return `${minutes} minutes ago`;
  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hour ago';
  if (hours < 24) return `${hours} hours ago`;
  const days = Math.floor(hours / 24);
  if (days === 1) return '1 day ago';
  return `${days} days ago`;
}
