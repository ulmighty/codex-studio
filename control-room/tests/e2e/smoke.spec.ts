import { test, expect } from '@playwright/test';

test('control room homepage renders core sections', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('main')).toHaveCount(1);
  await expect(page.locator('div.space-y-2')).toHaveCount(1);
  await expect(page.locator('ul.space-y-1')).toHaveCount(1);
  await expect(page.locator('div.bg-black')).toHaveCount(1);
  const logHeight = await page.locator('div.bg-black').evaluate((el) => el.clientHeight);
  expect(logHeight).toBeGreaterThan(0);
});
