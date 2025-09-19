import { NextResponse } from 'next/server';
import { readText } from '@/lib/fs';

export async function GET(_: Request, context: any) {
  const text = await readText(`patches/${context.params.name}`);
  return new NextResponse(text, { headers: { 'Content-Type': 'text/plain' } });
}
