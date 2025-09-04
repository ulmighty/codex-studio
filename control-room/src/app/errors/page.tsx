'use client';
import { useEffect, useState } from 'react';

export default function ErrorsPage() {
  const [errors, setErrors] = useState<string[]>([]);

  useEffect(() => {
    fetch('/api/state').then(r => r.json()).then(s => {
      setErrors(s.errors || []);
    });
  }, []);

  return (
    <div>
      <h1 className="text-xl mb-2">Errors</h1>
      <ul className="space-y-1">
        {errors.map((e, i) => <li key={i} className="text-red-400">{e}</li>)}
      </ul>
    </div>
  );
}
