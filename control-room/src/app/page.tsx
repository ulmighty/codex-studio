'use client';
import { useEffect, useState } from 'react';
import ProgressBoard from '@/components/ProgressBoard';
import LiveLog from '@/components/LiveLog';
import ChecksList from '@/components/ChecksList';
import FaceGallery from '@/components/FaceGallery';

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
      <FaceGallery
        faces={Array.isArray(state.faces) ? state.faces : []}
        privacyMode={Boolean(
          state.privacy_mode ?? state.privacyMode ?? state.privacy?.enabled ?? false,
        )}
        footer={state.privacy_notice ? (
          <p className="text-xs text-gray-400">{state.privacy_notice}</p>
        ) : undefined}
      />
      <ChecksList checks={checks} />
      <LiveLog />
    </main>
  );
}
