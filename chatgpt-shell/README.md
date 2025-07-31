# ChatGPT Shell

This project provides a secure desktop wrapper around chatgpt.com using Electron 30 and React.

```
packages/
  shell/   - Electron main & preload
  ui/      - Catalog UI built with React + Vite
  common/  - Shared code
```

Run `pnpm install` followed by `pnpm dev` to start development.

## Adding Apps

Edit `apps.json` and append records following the schema:

```json
{
  "id": "app-id",
  "name": "App Name",
  "icon": "https://example.com/icon.png",
  "url": "https://example.com",
  "partition": "persist:unique"
}
```

## Features
- Electron 30 with hardened defaults
- Catalog built with React + Vite
 - Apps listed in `apps.json` (ChatGPT, Meta AI, DeepSeek)
- Workspaces stored via `electron-store`
