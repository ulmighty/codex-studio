import { NextResponse } from 'next/server';
import { readText } from '@/lib/fs';

export async function GET(_: Request, { params }: { params: { name: string } }) {
  const text = await readText(`patches/${params.name}`);
  return new NextResponse(text, { headers: { 'Content-Type': 'text/plain' } });
}
