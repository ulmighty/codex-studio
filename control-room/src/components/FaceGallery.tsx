import type { ReactNode } from 'react';

import {
  FaceRecord,
  findFaceLabel,
  formatConfidence,
  isFaceLabelled,
  resolveFaceImage,
} from '@/lib/faces';

interface FaceGalleryProps {
  faces: unknown[];
  privacyMode: boolean;
  footer?: ReactNode;
}

export default function FaceGallery({ faces, privacyMode, footer }: FaceGalleryProps) {
  const normalisedFaces: FaceRecord[] = Array.isArray(faces)
    ? faces.filter((face): face is FaceRecord => !!face && typeof face === 'object')
    : [];

  return (
    <section className="space-y-3 rounded-lg border border-gray-800 bg-gray-900/60 p-4 shadow">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold text-white">Face Detections</h2>
        <span
          className={`text-xs uppercase tracking-wide ${
            privacyMode ? 'text-emerald-400' : 'text-gray-400'
          }`}
        >
          Privacy mode {privacyMode ? 'ON' : 'OFF'}
        </span>
      </div>

      {normalisedFaces.length === 0 ? (
        <p className="text-sm text-gray-400">No face detections available yet.</p>
      ) : (
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          {normalisedFaces.map((face, index) => {
            const labelled = isFaceLabelled(face);
            const shouldBlur = privacyMode && !labelled;
            const src = resolveFaceImage(face);
            const label = findFaceLabel(face) ?? `Face ${index + 1}`;
            const confidenceDisplay = formatConfidence(face.confidence);

            return (
              <div key={String(face.id ?? index)} className="rounded-lg bg-gray-800 p-2 shadow">
                <div className="relative overflow-hidden rounded border border-gray-700">
                  {src ? (
                    <img
                      src={src}
                      alt={label}
                      className={`h-32 w-full object-cover transition duration-200 ${
                        shouldBlur ? 'scale-105 filter blur-lg' : ''
                      }`}
                    />
                  ) : (
                    <div className="flex h-32 w-full items-center justify-center bg-gray-900 text-xs text-gray-500">
                      No preview
                    </div>
                  )}
                  {shouldBlur && <div className="absolute inset-0 bg-gray-900/40" aria-hidden="true" />}
                  <div className="absolute left-2 top-2 rounded bg-black/60 px-2 py-0.5 text-[10px] uppercase tracking-wide">
                    {labelled ? 'Labelled' : 'Unlabelled'}
                  </div>
                </div>
                <div className="mt-2 space-y-1 text-xs text-gray-300">
                  <div className="text-sm font-medium text-white">{label}</div>
                  {privacyMode && (
                    <div className={shouldBlur ? 'text-amber-400' : 'text-emerald-400'}>
                      {shouldBlur ? 'Blurred for privacy' : 'Visible'}
                    </div>
                  )}
                  {confidenceDisplay && <div className="text-gray-400">Confidence: {confidenceDisplay}</div>}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {footer}
    </section>
  );
}
