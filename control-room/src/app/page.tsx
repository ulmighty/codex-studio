import { FaceGallery } from '@/components/FaceGallery';
import { Timeline } from '@/components/Timeline';
import { Wordcloud } from '@/components/Wordcloud';
import { Spectrogram } from '@/components/Spectrogram';
import { SettingsPanel } from '@/components/SettingsPanel';

export default function Page() {
  return (
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
    </main>
  );
}
