import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  retries: 0,
  use: {
    headless: true,
    baseURL: 'http://127.0.0.1:3100',
  },
  webServer: {
    command: 'npm run build && npm run start -- --hostname 127.0.0.1 --port 3100',
    cwd: __dirname,
    port: 3100,
    reuseExistingServer: !process.env.CI,
  },
});
