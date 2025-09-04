'use client';
import { useEffect, useRef, useState } from 'react';

export default function LiveLog() {
  const [paused, setPaused] = useState(false);
  const [lines, setLines] = useState<string[]>([]);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const es = new EventSource('/api/log/stream');
    es.onmessage = (e) => {
      if (!paused) setLines((l) => [...l.slice(-200), e.data]);
    };
    const key = (e: KeyboardEvent) => {
      if (e.key === 'l') setPaused((p) => !p);
    };
    window.addEventListener('keydown', key);
    return () => {
      es.close();
      window.removeEventListener('keydown', key);
    };
  }, [paused]);

  useEffect(() => {
    if (!paused) endRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [lines, paused]);

  return (
    <div className="bg-black text-green-400 p-2 h-48 overflow-y-auto text-xs">
      {lines.map((l, i) => <div key={i}>{l}</div>)}
      <div ref={endRef} />
    </div>
  );
}
