import React from 'react';
import { createRoot } from 'react-dom/client';

function Options(): JSX.Element {
  return <div>Options</div>;
}

const root = createRoot(document.getElementById('root') as HTMLElement);
root.render(<Options />);
