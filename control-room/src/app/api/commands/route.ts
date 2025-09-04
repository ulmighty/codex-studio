import { NextResponse } from 'next/server';
import { appendCommand, readJson } from '@/lib/fs';

const TYPES = [
  'request_retry',
  'request_rebuild_phase',
  'pause_pipeline',
  'resume_pipeline',
  'open_patch',
  'approve_overwrite',
  'run_checks'
];

export async function POST(req: Request) {
  const body = await req.json();
  if (!TYPES.includes(body.type)) {
    return NextResponse.json({ error: 'invalid type' }, { status: 400 });
  }
  const state = await readJson('state.json', {});
  const cmd = {
    ts: new Date().toISOString(),
    actor: 'gui',
    type: body.type,
    payload: body.payload || {},
    blueprint_hash: state.blueprint_hash || ''
  };
  await appendCommand(cmd);
  return NextResponse.json(cmd);
}
