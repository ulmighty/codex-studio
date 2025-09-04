import { NextResponse } from 'next/server';
import { listDir, safeJoin } from '@/lib/fs';
import fs from 'fs';

export async function GET() {
  const dir = safeJoin('patches');
  const files = await listDir('patches');
  const list = files.map(name => ({ name, size: fs.statSync(safeJoin('patches', name)).size }));
  return NextResponse.json(list);
}
