'use client';

import { useEffect, useMemo, useState } from 'react';
import { getTranscript } from '@/lib/api';

const STOP_WORDS = new Set([
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'by',
  'for',
  'from',
  'has',
  'in',
  'is',
  'it',
  'of',
  'on',
  'or',
  'that',
  'the',
  'to',
  'was',
  'were',
  'with'
]);

type WordDatum = {
  word: string;
  weight: number;
  count: number;
};

export function Wordcloud() {
  const [transcript, setTranscript] = useState('');

  useEffect(() => {
    let active = true;
    getTranscript().then((text) => {
      if (!active) return;
      setTranscript(text);
    });
    return () => {
      active = false;
    };
  }, []);

  const cloud = useMemo<WordDatum[]>(() => {
    if (!transcript) return [];
    const counts = new Map<string, number>();
    transcript
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter((token) => token && !STOP_WORDS.has(token))
      .forEach((token) => {
        counts.set(token, (counts.get(token) ?? 0) + 1);
      });

    const entries = Array.from(counts.entries()).sort((a, b) => b[1] - a[1]).slice(0, 40);
    const max = entries[0]?.[1] ?? 1;
    return entries.map(([word, count]) => ({
      word,
      count,
      weight: count / max
    }));
  }, [transcript]);

  return (
    <section className="rounded-2xl border border-gray-800 bg-gray-900/70 p-6 shadow-xl shadow-black/20">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-50">Transcript Wordcloud</h2>
          <p className="text-sm text-gray-400">Highlights of frequently mentioned topics.</p>
        </div>
        <span className="text-xs text-gray-500">Top {cloud.length} terms</span>
      </header>
      {cloud.length > 0 ? (
        <div className="flex flex-wrap gap-3">
          {cloud.map(({ word, weight, count }) => (
            <span
              key={word}
              className="rounded-full bg-gray-950/70 px-3 py-1 text-gray-200 shadow-md shadow-black/10"
              style={{
                fontSize: `${clamp(0.9, 1.8, weight * 1.8)}rem`,
                opacity: clamp(0.55, 1, weight + 0.2)
              }}
              title={`${count} mentions`}
            >
              {word}
            </span>
          ))}
        </div>
      ) : (
        <p className="text-sm text-gray-400">Transcript feed not yet available.</p>
      )}
    </section>
  );
}

function clamp(min: number, max: number, value: number) {
  return Math.max(min, Math.min(max, value));
}
