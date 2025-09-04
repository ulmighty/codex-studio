'use client';
import { useEffect, useState } from 'react';

export default function PatchList() {
  const [list, setList] = useState<any[]>([]);
  const [content, setContent] = useState('');

  useEffect(() => {
    fetch('/api/patches').then(r => r.json()).then(setList);
  }, []);

  const open = async (name: string) => {
    const txt = await fetch(`/api/patches/${name}`).then(r => r.text());
    setContent(txt);
  };

  return (
    <div className="flex space-x-4">
      <ul className="w-1/3 space-y-1">
        {list.map((p: any) => (
          <li key={p.name}>
            <button onClick={() => open(p.name)} className="underline">
              {p.name} ({p.size})
            </button>
          </li>
        ))}
      </ul>
      <pre className="flex-1 bg-gray-800 p-2 overflow-auto text-xs">{content}</pre>
    </div>
  );
}
