import { expect, test } from "@playwright/test";

const viewports = [
  {name:"small phone",width:320,height:740},
  {name:"standard phone",width:390,height:844},
  {name:"large phone",width:430,height:932},
  {name:"tablet portrait",width:768,height:1024},
  {name:"tablet landscape",width:1180,height:820},
  {name:"desktop",width:1440,height:900}
];

for (const viewport of viewports) {
  test(`home and navigation fit ${viewport.name}`, async ({page}) => {
    await page.setViewportSize({width:viewport.width,height:viewport.height});
    await page.goto("/");
    await expect(page.getByRole("heading",{name:/Kannada word reading/})).toBeVisible();
    await expect(page.getByRole("navigation",{name:"Main navigation"})).toBeVisible();
    const width = await page.evaluate(() => ({
      viewport: document.documentElement.clientWidth,
      content: document.documentElement.scrollWidth
    }));
    expect(width.content).toBeLessThanOrEqual(width.viewport + 1);
    await expect(page.getByRole("button",{name:/Home/})).toBeVisible();
    await expect(page.getByRole("button",{name:/Game/})).toBeVisible();
  });
}

test("assessor setup fields remain usable on a phone", async ({page}) => {
  await page.setViewportSize({width:390,height:844});
  await page.goto("/");
  await page.getByRole("button",{name:/Setup/}).click();
  await expect(page.getByRole("heading",{name:"Assessment setup"})).toBeVisible();
  await page.getByPlaceholder("KWR-0001").fill("DEMO-CHILD-01");
  await page.getByPlaceholder("ASR-003").fill("DEMO-ASSESSOR");
  await expect(page.getByPlaceholder("KWR-0001")).toHaveValue("DEMO-CHILD-01");
  const width = await page.evaluate(() => document.documentElement.scrollWidth);
  expect(width).toBeLessThanOrEqual(391);
});

test("child demo starts full-screen and pauses for milestone reward", async ({page}) => {
  await page.setViewportSize({width:390,height:844});
  await page.goto("/");
  await page.getByRole("button",{name:/Game/}).click();
  await page.getByRole("button",{name:/ಆಟ ಪ್ರಾರಂಭಿಸಿ/}).click();

  const prompt = page.getByText("ಈ ಪದ ನಿಜವಾದ ಪದವೇ?");
  await expect(prompt).toBeVisible();

  // Complete the five practice examples, then five demo-scored examples.
  for (let i=0;i<10;i++) {
    await page.getByRole("button",{name:"ಪದ",exact:true}).click();
  }
  await expect(page.getByText(/ಚಿಕ್ಕ ಬಹುಮಾನ/)).toBeVisible();
  await expect(page.getByRole("button",{name:/ಮುಂದುವರಿಸಿ/})).toBeVisible();
  await page.getByRole("button",{name:/ಮುಂದುವರಿಸಿ/}).click();
  await expect(page.getByText("ಈ ಪದ ನಿಜವಾದ ಪದವೇ?")).toBeVisible();
  const childMode = await page.locator("main.shell").evaluate(el=>el.classList.contains("is-playing"));
  expect(childMode).toBe(true);
});

test("item-bank template endpoint returns an Excel workbook", async ({request}) => {
  const response = await request.get("/templates/kannada-item-bank-template.xlsx");
  expect(response.ok()).toBe(true);
  expect(response.headers()["content-type"]).toContain("spreadsheetml.sheet");
  expect((await response.body()).byteLength).toBeGreaterThan(5_000);
});

test("internal app sets security headers and no-index policy", async ({page,request}) => {
  const response = await page.goto("/");
  expect(response?.status()).toBe(200);
  const headers = response?.headers() ?? {};
  expect(headers["x-content-type-options"]).toBe("nosniff");
  expect(headers["x-frame-options"]).toBe("DENY");
  expect(headers["referrer-policy"]).toBe("strict-origin-when-cross-origin");
  expect(headers["permissions-policy"]).toContain("camera=()");
  await expect(page.locator('meta[name="robots"]')).toHaveAttribute("content", /noindex/);
  const robots = await request.get("/robots.txt");
  expect(robots.ok()).toBe(true);
  expect(await robots.text()).toContain("Disallow: /");
});
