'use client';
import { useEffect, useState } from 'react';

const TYPES = [
  'request_retry',
  'request_rebuild_phase',
  'pause_pipeline',
  'resume_pipeline',
  'open_patch',
  'approve_overwrite',
  'run_checks'
];

export function InterveneTray() {
  const [open, setOpen] = useState(false);
  const [outbox, setOutbox] = useState<any[]>([]);

  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.key === 'p') setOpen((o) => !o);
    };
    window.addEventListener('keydown', key);
    return () => window.removeEventListener('keydown', key);
  }, []);

  const send = async (type: string) => {
    const res = await fetch('/api/commands', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type })
    });
    if (res.ok) {
      const json = await res.json();
      setOutbox((o) => [json, ...o]);
    }
  };

  if (!open) return (
    <button onClick={() => setOpen(true)} className="fixed bottom-2 right-2 bg-blue-600 text-white px-3 py-1 rounded">Intervene</button>
  );

  return (
    <div className="fixed bottom-2 right-2 bg-gray-800 p-4 rounded shadow space-y-2 w-56">
      <button onClick={() => setOpen(false)} className="absolute top-1 right-1">x</button>
      {TYPES.map(t => (
        <button key={t} onClick={() => send(t)} className="block w-full text-left hover:bg-gray-700 px-2">
          {t}
        </button>
      ))}
      <div className="mt-2 text-xs">Outbox:</div>
      <ul className="max-h-24 overflow-y-auto text-xs">
        {outbox.map((c, i) => <li key={i}>{c.type} – {c.ts}</li>)}
      </ul>
    </div>
  );
}
