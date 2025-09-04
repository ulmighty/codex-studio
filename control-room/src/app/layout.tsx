import '../styles/globals.css';
import { Topbar } from '@/components/Topbar';
import { InterveneTray } from '@/components/InterveneTray';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className="bg-gray-900 text-gray-100">
        <Topbar />
        <div className="p-4 min-h-screen">
          {children}
        </div>
        <InterveneTray />
      </body>
    </html>
  );
}
