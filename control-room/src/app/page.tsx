'use client';
import { useEffect, useState } from 'react';
import ProgressBoard from '@/components/ProgressBoard';
import LiveLog from '@/components/LiveLog';
import ChecksList from '@/components/ChecksList';

export default function Page() {
  const [state, setState] = useState<any>({});
  const [checks, setChecks] = useState<any[]>([]);

  useEffect(() => {
    fetch('/api/state').then(r => r.json()).then(setState);
    fetch('/api/checks').then(r => r.json()).then(d => setChecks(d.checks || []));
  }, []);

  return (
    <main className="space-y-4">
      <ProgressBoard data={state} />
      <ChecksList checks={checks} />
      <LiveLog />
    </main>
  );
}
