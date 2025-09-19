'use client';

import { useEffect, useState, type ChangeEvent } from 'react';
import type { PrivacySettings } from '@/lib/api';
import { getPrivacySettings, updatePrivacySettings } from '@/lib/api';

export function SettingsPanel() {
  const [settings, setSettings] = useState<PrivacySettings | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    getPrivacySettings().then((data) => {
      if (!active) return;
      setSettings(data);
    });
    return () => {
      active = false;
    };
  }, []);

  const persist = async (next: PrivacySettings) => {
    setSettings(next);
    setIsSaving(true);
    const saved = await updatePrivacySettings(next);
    setSettings(saved);
    setIsSaving(false);
    setMessage('Settings saved');
    setTimeout(() => setMessage(null), 2000);
  };

  if (!settings) {
    return (
      <section className="rounded-2xl border border-gray-800 bg-gray-900/70 p-6 text-sm text-gray-400 shadow-xl shadow-black/20">
        Loading privacy settings…
      </section>
    );
  }

  return (
    <section className="rounded-2xl border border-gray-800 bg-gray-900/70 p-6 shadow-xl shadow-black/20">
      <header className="mb-6 flex items-center justify-between">
        <div>
          <h2 className="text-lg font-semibold text-gray-50">Privacy &amp; Thresholds</h2>
          <p className="text-sm text-gray-400">Manage automatic redaction and detection sensitivity.</p>
        </div>
        {message ? <span className="text-xs text-emerald-300">{message}</span> : null}
      </header>
      <div className="space-y-6">
        <div className="flex items-center justify-between gap-4 rounded-xl border border-gray-800 bg-gray-950/60 p-4">
          <div>
            <h3 className="text-sm font-semibold text-gray-100">Automatic privacy blur</h3>
            <p className="text-sm text-gray-400">Masks PII in live feeds before distribution.</p>
          </div>
          <button
            type="button"
            onClick={() => persist({ ...settings, privacyBlur: !settings.privacyBlur })}
            className={`relative h-7 w-12 rounded-full border transition ${
              settings.privacyBlur
                ? 'border-emerald-500/60 bg-emerald-500/30'
                : 'border-gray-700 bg-gray-800'
            }`}
          >
            <span
              className={`absolute top-1/2 h-5 w-5 -translate-y-1/2 rounded-full bg-white transition ${
                settings.privacyBlur ? 'translate-x-6 shadow-inner shadow-emerald-500/30' : 'translate-x-1 shadow'
              }`}
            />
          </button>
        </div>

        <Slider
          label="Recognition confidence"
          description="Minimum score required before a face is considered a match."
          value={settings.recognitionThreshold}
          onChange={(value) => persist({ ...settings, recognitionThreshold: value })}
        />

        <Slider
          label="Anomaly alert threshold"
          description="Tune how sensitive the acoustic monitors are before pushing an alert."
          value={settings.anomalyThreshold}
          onChange={(value) => persist({ ...settings, anomalyThreshold: value })}
        />
      </div>
      {isSaving ? <p className="mt-4 text-xs text-gray-500">Saving…</p> : null}
    </section>
  );
}

interface SliderProps {
  label: string;
  description: string;
  value: number;
  onChange: (next: number) => void;
}

function Slider({ label, description, value, onChange }: SliderProps) {
  const handleChange = (event: ChangeEvent<HTMLInputElement>) => {
    const parsed = Number.parseFloat(event.target.value);
    onChange(Number.isFinite(parsed) ? parsed : value);
  };

  return (
    <div className="space-y-3 rounded-xl border border-gray-800 bg-gray-950/60 p-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h3 className="text-sm font-semibold text-gray-100">{label}</h3>
          <p className="text-sm text-gray-400">{description}</p>
        </div>
        <span className="rounded-full border border-gray-800 bg-gray-900 px-2 py-1 text-xs text-gray-300">
          {(value * 100).toFixed(0)}%
        </span>
      </div>
      <input
        type="range"
        min={0.3}
        max={0.99}
        step={0.01}
        value={value}
        onChange={handleChange}
        className="h-2 w-full cursor-pointer appearance-none rounded-full bg-gray-800 accent-emerald-500"
      />
    </div>
  );
}
