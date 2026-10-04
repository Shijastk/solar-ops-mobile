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
      // Flutter 3.35 uses text spans for leaf labels, aria-label for containers.
      await page.getByText(label, { exact: false })
        .or(page.locator(`[aria-label*="${label}"]`)).first()
        .waitFor({ state: 'attached' });
    }
    async function screenshot(name) {
      await page.screenshot({ path: `ui-screenshots/${name}.png` });
    }
    await expectLabel('Tirur');
    await screenshot('01-trips');
    await page.mouse.click(195, 804);
    await expectLabel('First panel');
    await screenshot('02-stock');
    await page.mouse.click(324, 804);
    await expectLabel('INV-1');
    await screenshot('03-history');
    await page.mouse.click(145, 28);
    await expectLabel('Second Solar Company Limited');
    // ListTile merges the company name and GSTIN into one accessible text span.
    await page.getByText('Second Solar Company Limited', { exact: false }).click();
    await expectLabel('INV-2');
    const firstCompanyBill = page.getByText('INV-1', { exact: false })
      .or(page.locator('[aria-label*="INV-1"]'));
    await firstCompanyBill.first().waitFor({ state: 'detached' });
    assert.equal(await firstCompanyBill.count(), 0);
    await page.mouse.click(362, 28);
    await expectLabel('Settings');
    await page.getByText('Settings', { exact: false }).or(page.locator('[aria-label="Settings"]')).first().click();
    await expectLabel('Device lock');
    await screenshot('04-settings');
    await page.mouse.click(27, 28);
    await page.mouse.click(362, 28);
    await page.getByText('Company profile', { exact: false }).or(page.locator('[aria-label="Company profile"]')).first().click();
    await expectLabel('Change photo');
    await expectLabel('33AAAAA0000A1Z5');
    await screenshot('05-company-profile');
    await page.mouse.click(27, 28);
    await page.setViewportSize({ width: 320, height: 740 });
    await screenshot('06-company-history-narrow');
    assert.deepEqual(errors, []);
    console.log('PASS: trips, stock, history, company switching, settings and profile; no page errors');
  } catch (error) {
    await page.screenshot({ path: 'ui-screenshots/failure.png' });
    fs.writeFileSync('ui-screenshots/semantics.txt', await page.locator('flt-semantics').evaluateAll(
      elements => elements.map(e => `${e.getAttribute('aria-label') || ''} ${e.textContent || ''}`).join('\n')));
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
