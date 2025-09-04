export default function ProgressBoard({ data }: { data: any }) {
  const phases = data.phases || [];
  return (
    <div className="space-y-2">
      {phases.map((p: any) => (
        <div key={p.name}>
          <div className="text-sm">{p.name}</div>
          <div className="bg-gray-700 h-2 rounded">
            <div className="bg-blue-500 h-2 rounded" style={{ width: `${p.progress || 0}%` }} />
          </div>
        </div>
      ))}
    </div>
  );
}
