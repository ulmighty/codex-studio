import { NextResponse } from 'next/server';
import { readJson } from '@/lib/fs';

export async function GET() {
  const data = await readJson('state.json', {});
  return NextResponse.json(data);
}
