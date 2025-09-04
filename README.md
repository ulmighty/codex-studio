# NexusForge Control Room

Control Room provides a lightweight GUI to observe the NexusForge build
pipeline and queue interventions.

## Run

```sh
docker compose up --build
```

The container bind-mounts `~/NexusForge` to `/workspace` and listens on
http://localhost:3000.

## Workspace

The GUI reads from `/workspace/.nexusforge`:
- `state.json` – build state
- `run.log` – append-only log
- `checklist.md` – acceptance checks
- `patches/` – diff files
- `policy.json` – DeepSeek policy
- `commands/queue.jsonl` – command queue (append only)

POSTing to `/api/commands` appends a JSON line to the command queue for an
external orchestrator to handle.
