import { NextResponse } from 'next/server';
import { readText } from '@/lib/fs';

export async function GET() {
  const md = await readText('checklist.md');
  const checks = md.split('\n').filter(Boolean).map(line => {
    const m = line.match(/^- \[( |x)\] (.+)$/);
    return { text: m ? m[2] : line, status: m ? (m[1] === 'x' ? 'done' : 'todo') : 'note' };
  });
  return NextResponse.json({ checks });
}
