codex/implement-fetch-wrappers-in-lib/api.ts
import { FaceGallery } from '@/components/FaceGallery';
import { Timeline } from '@/components/Timeline';
import { Wordcloud } from '@/components/Wordcloud';
import { Spectrogram } from '@/components/Spectrogram';
import { SettingsPanel } from '@/components/SettingsPanel';
'use client';
import { useEffect, useState } from 'react';
import ProgressBoard from '@/components/ProgressBoard';
import LiveLog from '@/components/LiveLog';
import ChecksList from '@/components/ChecksList';
import FaceGallery from '@/components/FaceGallery';
main

export default function Page() {
  return (
codex/implement-fetch-wrappers-in-lib/api.ts
    <main className="mx-auto flex max-w-7xl flex-col gap-6">
      <div className="grid grid-cols-1 gap-6 xl:grid-cols-5">
        <div className="xl:col-span-3">
          <FaceGallery />
        </div>
        <div className="flex flex-col gap-6 xl:col-span-2">
          <Spectrogram />
          <SettingsPanel />
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-5">
        <div className="xl:col-span-3">
          <Timeline />
        </div>
        <div className="xl:col-span-2">
          <Wordcloud />
        </div>
      </div>
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
main
    </main>
  );
}
