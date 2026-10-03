// Uses synthetic fixture data; it never signs in or changes production records.
const { chromium } = require(process.env.SOLAR_UI_MODULE || 'playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');

(async () => {
  fs.mkdirSync('ui-screenshots', { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  try {
    await page.goto('http://127.0.0.1:8765', { waitUntil: 'networkidle' });
    const accessibility = page.locator('flt-semantics-placeholder');
    await accessibility.waitFor({ state: 'attached' });
    await accessibility.evaluate(element => element.click());

    async function expectLabel(label) {
      await page.locator(`[aria-label*="${label}"]`).first().waitFor({ state: 'attached' });
    }
    async function screenshot(name) {
      await page.screenshot({ path: `ui-screenshots/${name}.png` });
    }
    await expectLabel('Tirur');
    await screenshot('01-trips');
    await page.mouse.click(195, 804);
    await expectLabel('First panel');
    await screenshot('02-stock');
    await page.mouse.click(325, 804);
    await expectLabel('INV-1');
    await screenshot('03-history');
    await page.mouse.click(100, 28);
    await expectLabel('Second Solar Company Limited');
    await page.locator('[aria-label="Second Solar Company Limited"]').first().click();
    await expectLabel('INV-2');
    assert.equal(await page.locator('[aria-label*="INV-1"]').count(), 0);
    await page.setViewportSize({ width: 320, height: 740 });
    await screenshot('04-company-history-narrow');
    assert.deepEqual(errors, []);
    console.log('PASS: trips, stock, history and company switching; no page errors');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
