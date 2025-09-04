'use client';
import { useEffect, useRef, useState } from 'react';

export function Topbar() {
  const search = useRef<HTMLInputElement>(null);
  const [state, setState] = useState<any>({});

  useEffect(() => {
    fetch('/api/state').then(r => r.json()).then(setState);
    const key = (e: KeyboardEvent) => {
      if (e.key === '/') {
        e.preventDefault();
        search.current?.focus();
      }
    };
    window.addEventListener('keydown', key);
    return () => window.removeEventListener('keydown', key);
  }, []);

  return (
    <div className="flex items-center justify-between px-4 py-2 bg-gray-800">
      <div className="font-bold">NexusForge – {state.blueprint_hash || ''}</div>
      <input ref={search} placeholder="Search" className="bg-gray-700 rounded px-2 py-1 text-sm" />
    </div>
  );
}
