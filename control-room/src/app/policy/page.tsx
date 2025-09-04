'use client';
import { useEffect, useState } from 'react';

export default function PolicyPage() {
  const [policy, setPolicy] = useState<any>({});

  useEffect(() => {
    fetch('/api/policy').then(r => r.json()).then(setPolicy);
  }, []);

  return (
    <div className="space-y-2">
      <h1 className="text-xl">Policy</h1>
      <pre className="bg-gray-800 p-2 overflow-auto text-sm">{JSON.stringify(policy, null, 2)}</pre>
      <div className="text-sm text-gray-400">
        <ul className="list-disc ml-4">
          <li>model_for_code = deepseek-chat</li>
          <li>temperature = 0.0</li>
          <li>response_format = {`{"type":"json_object"}`}</li>
          <li>stable system preface / context caching enabled</li>
        </ul>
      </div>
    </div>
  );
}
