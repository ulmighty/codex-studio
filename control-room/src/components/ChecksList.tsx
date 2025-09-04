export default function ChecksList({ checks }: { checks: any[] }) {
  return (
    <ul className="space-y-1">
      {checks.map((c, i) => (
        <li key={i} className="flex items-center space-x-2">
          <span>{c.status === 'done' ? '✅' : c.status === 'fail' ? '❌' : '⬜'}</span>
          <span>{c.text}</span>
        </li>
      ))}
    </ul>
  );
}
