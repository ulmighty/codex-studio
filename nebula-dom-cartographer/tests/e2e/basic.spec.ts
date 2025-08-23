import { test, expect } from '@playwright/test';

test('page loads', async ({ page }) => {
  await page.goto('about:blank');
  await expect(page).toHaveTitle('');
});
