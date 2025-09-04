import { NextResponse } from 'next/server';
import { readJson } from '@/lib/fs';

export async function GET() {
  const policy = await readJson('policy.json', {});
  return NextResponse.json(policy);
}
