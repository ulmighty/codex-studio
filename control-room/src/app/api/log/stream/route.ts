import { NextResponse } from 'next/server';
import { tailStream } from '@/lib/fs';

export async function GET() {
  const stream = tailStream('run.log');
  return new NextResponse(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
