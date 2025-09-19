import '../styles/globals.css';
import { Topbar } from '@/components/Topbar';
import { InterveneTray } from '@/components/InterveneTray';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-gray-950 text-gray-100">
        <Topbar />
        <div className="px-4 pb-16 pt-8 sm:px-6">
          {children}
        </div>
        <InterveneTray />
      </body>
    </html>
  );
}
