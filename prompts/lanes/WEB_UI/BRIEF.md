# WEB_UI Lane Brief

## Goals
- Ship a dark-themed Next.js interface for browsing FaceTrace findings offline.
- Guarantee privacy mode: blur unlabelled faces in all thumbnails/previews and surface an explicit toggle state indicator.
- Display Whisper transcripts with the mandated “may be inaccurate” disclaimer and attribute sources.
- Provide responsive layouts and offline-ready asset bundling (no CDN dependencies).

## Primary Files and Directories
- `apps/web/` – Next.js application, components, styling, and static assets.
- `apps/web/public/` – placeholder fixtures for offline demos (no sensitive media).
- `apps/web/config/` – environment configuration bridging to BACKEND_API endpoints.
- `tests/web/` – unit and integration tests using Jest/Playwright (headless) with minimal fixtures.

## Acceptance Checks
- `npm run lint` and `npm run test` complete within CI resource limits using local dependencies only.
- Privacy toggle verified through automated tests ensuring blurred fallback when labels absent.
- Transcript panels always include disclaimer text and deterministic timestamp formatting.
- `ARTIFACTS.md` lists built assets, env variable defaults, and screenshot references for QC.

## CI Steps
- `npm install` (offline cache expected via lockfile)
- `npm run lint`
- `npm run test`
- `scripts/verify-structure.sh`
