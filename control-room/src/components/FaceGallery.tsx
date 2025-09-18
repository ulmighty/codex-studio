'use client';

import { useEffect, useMemo, useState } from 'react';
import type { FaceCluster } from '@/lib/api';
import { getFaceClusters } from '@/lib/api';

interface CompareSelection {
  primary?: string;
  secondary?: string;
}

export function FaceGallery() {
  const [clusters, setClusters] = useState<FaceCluster[]>([]);
  const [selectedClusterId, setSelectedClusterId] = useState<string | null>(null);
  const [compareSelection, setCompareSelection] = useState<CompareSelection>({});

  useEffect(() => {
    let active = true;
    getFaceClusters().then((data) => {
      if (!active) return;
      setClusters(data);
      if (!selectedClusterId && data.length > 0) {
        setSelectedClusterId(data[0].id);
      }
    });
    return () => {
      active = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const selectedCluster = useMemo(
    () => clusters.find((cluster) => cluster.id === selectedClusterId) ?? null,
    [clusters, selectedClusterId]
  );

  const toggleCompare = (appearanceId: string) => {
    setCompareSelection((selection) => {
      if (selection.primary === appearanceId) {
        const { secondary } = selection;
        return { primary: secondary, secondary: undefined };
      }
      if (selection.secondary === appearanceId) {
        return { ...selection, secondary: undefined };
      }
      if (!selection.primary) {
        return { primary: appearanceId };
      }
      if (!selection.secondary) {
        return { ...selection, secondary: appearanceId };
      }
      return { primary: appearanceId, secondary: selection.primary };
    });
  };

  const comparePair = useMemo(() => {
    if (!selectedCluster) return [];
    return selectedCluster.appearances.filter((appearance) =>
      appearance.id === compareSelection.primary || appearance.id === compareSelection.secondary
    );
  }, [compareSelection.primary, compareSelection.secondary, selectedCluster]);

  return (
    <section className="rounded-2xl border border-gray-800 bg-gray-900/70 p-6 shadow-xl shadow-black/20">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-50">Face Gallery</h2>
          <p className="text-sm text-gray-400">Clustered recognitions with quick comparisons.</p>
        </div>
        <span className="rounded-full border border-emerald-500/40 bg-emerald-500/10 px-3 py-1 text-xs font-medium text-emerald-300">
          {clusters.length} clusters
        </span>
      </header>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {clusters.map((cluster) => {
          const isSelected = cluster.id === selectedClusterId;
          return (
            <button
              key={cluster.id}
              type="button"
              onClick={() => setSelectedClusterId(cluster.id)}
              className={`group rounded-xl border px-4 py-3 text-left transition-colors focus:outline-none focus:ring-2 focus:ring-emerald-500/50 ${
                isSelected
                  ? 'border-emerald-500/50 bg-emerald-500/10 shadow-lg shadow-emerald-500/20'
                  : 'border-gray-800 bg-gray-900/80 hover:border-gray-700'
              }`}
            >
              <div className="flex items-center justify-between gap-3">
                <div>
                  <p className="font-medium text-gray-100">{cluster.label}</p>
                  <p className="text-xs text-gray-400">Last seen {formatRelativeTime(cluster.lastSeen)}</p>
                </div>
                <div className="text-right text-xs text-gray-400">
                  <div className="text-emerald-300">{Math.round(cluster.confidence * 100)}% match</div>
                  <div>{cluster.appearances.length} appearances</div>
                </div>
              </div>
              <div className="mt-3 flex flex-wrap gap-2">
                {cluster.appearances.slice(0, 4).map((appearance) => (
                  <PreviewAvatar key={appearance.id} thumbnail={appearance.thumbnail} label={cluster.label} />
                ))}
                {cluster.appearances.length > 4 ? (
                  <span className="rounded-full border border-gray-700 bg-gray-800 px-2 text-xs text-gray-400">
                    +{cluster.appearances.length - 4}
                  </span>
                ) : null}
              </div>
            </button>
          );
        })}
      </div>

      {selectedCluster ? (
        <div className="mt-6 space-y-4">
          <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
            <div>
              <h3 className="text-base font-semibold text-gray-50">Appearances for {selectedCluster.label}</h3>
              <p className="text-sm text-gray-400">
                Select up to two clips to launch a side-by-side comparison.
              </p>
            </div>
            <div className="text-xs text-gray-500">
              Confidence threshold {Math.round(selectedCluster.confidence * 100)}%
            </div>
          </div>
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            {selectedCluster.appearances.map((appearance) => {
              const active =
                compareSelection.primary === appearance.id || compareSelection.secondary === appearance.id;
              return (
                <button
                  key={appearance.id}
                  type="button"
                  onClick={() => toggleCompare(appearance.id)}
                  className={`flex flex-col gap-3 rounded-xl border bg-gray-950/50 p-4 text-left transition hover:border-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500/40 ${
                    active ? 'border-emerald-400/60 shadow-inner shadow-emerald-500/30' : 'border-gray-800'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className="relative h-20 w-20 overflow-hidden rounded-lg border border-gray-800 bg-gray-900">
                      {appearance.thumbnail ? (
                        <img
                          src={appearance.thumbnail}
                          alt={`${selectedCluster.label} at ${appearance.timecode}`}
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full w-full items-center justify-center text-sm text-gray-500">
                          {selectedCluster.label
                            .split(' ')
                            .map((part) => part[0])
                            .join('')}
                        </div>
                      )}
                      {active ? (
                        <span className="absolute left-1 top-1 rounded-full bg-emerald-500 px-2 py-0.5 text-[10px] font-semibold text-emerald-950">
                          Selected
                        </span>
                      ) : null}
                    </div>
                    <div className="space-y-1 text-sm">
                      <div className="font-medium text-gray-200">Timestamp {appearance.timecode}</div>
                      <div className="text-gray-400">{appearance.context}</div>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          <div className="rounded-xl border border-emerald-500/20 bg-emerald-500/5 p-4">
            {comparePair.length === 2 ? (
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                {comparePair.map((appearance) => (
                  <div key={appearance.id} className="space-y-3 rounded-lg border border-emerald-500/20 bg-gray-950/60 p-3">
                    <div className="flex items-center justify-between text-sm text-gray-400">
                      <span>{appearance.timecode}</span>
                      <span>{appearance.context}</span>
                    </div>
                    <div className="relative h-40 overflow-hidden rounded-md border border-gray-900 bg-gray-900">
                      {appearance.thumbnail ? (
                        <img
                          src={appearance.thumbnail}
                          alt={`${selectedCluster.label} reference frame`}
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <div className="flex h-full items-center justify-center text-sm text-gray-500">
                          Frame unavailable
                        </div>
                      )}
                    </div>
                    <div className="text-xs text-gray-500">
                      Confidence {Math.round(selectedCluster.confidence * 100)}% • Manual review enabled
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-emerald-200">
                Choose two appearances above to open the rapid compare view. This view synchronises clips and surfaces
                contextual metadata for manual validation.
              </p>
            )}
          </div>
        </div>
      ) : null}
    </section>
  );
}

function PreviewAvatar({ thumbnail, label }: { thumbnail?: string; label: string }) {
  if (!thumbnail) {
    const initials = label
      .split(' ')
      .map((part) => part[0])
      .join('');
    return (
      <span className="flex h-8 w-8 items-center justify-center rounded-full border border-gray-700 bg-gray-800 text-xs font-medium text-gray-200">
        {initials}
      </span>
    );
  }
  return (
    <span className="h-8 w-8 overflow-hidden rounded-full border border-gray-700">
      <img src={thumbnail} alt={label} className="h-full w-full object-cover" />
    </span>
  );
}

function formatRelativeTime(isoDate: string) {
  const now = new Date();
  const target = new Date(isoDate);
  const diff = Math.max(0, now.getTime() - target.getTime());
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'just now';
  if (minutes === 1) return '1 minute ago';
  if (minutes < 60) return `${minutes} minutes ago`;
  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hour ago';
  if (hours < 24) return `${hours} hours ago`;
  const days = Math.floor(hours / 24);
  if (days === 1) return '1 day ago';
  return `${days} days ago`;
}
