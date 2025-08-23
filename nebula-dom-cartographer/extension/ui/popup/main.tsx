import React from 'react';
import { createRoot } from 'react-dom/client';

function App(): JSX.Element {
  return <div>Nebula DOM Cartographer</div>;
}

const root = createRoot(document.getElementById('root') as HTMLElement);
root.render(<App />);
