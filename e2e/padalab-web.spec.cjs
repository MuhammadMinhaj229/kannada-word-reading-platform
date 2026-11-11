const { test, expect } = require("@playwright/test");

const CANDIDATE_CSV =
  "/assets/assets/item_bank/nonword_candidates_supplied_v1.csv";
const ALLOCATION_JSON =
  "/assets/assets/item_bank/allocation_proposal_v2.json";

async function expectFlutterMounted(page) {
  await expect(page.locator("flutter-view").first()).toBeAttached();
  await expect(page.locator("flt-glass-pane").first()).toBeAttached();
  const bounds = await page.locator("flutter-view").first().boundingBox();
  expect(bounds).not.toBeNull();
  expect(bounds.width).toBeGreaterThan(0);
  expect(bounds.height).toBeGreaterThan(0);
}

async function expectFlutterWidth(page, width) {
  await expect
    .poll(
      async () => {
        const bounds = await page.locator("flutter-view").first().boundingBox();
        return bounds ? Math.round(bounds.width) : 0;
      },
      { timeout: 15_000 },
    )
    .toBe(width);
}

test("Flutter Web boots without uncaught browser errors", async ({ page }) => {
  const pageErrors = [];
  const consoleErrors = [];

  page.on("pageerror", (error) => pageErrors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });

  const response = await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(response).not.toBeNull();
  expect(response.status()).toBe(200);
  await expect(page).toHaveTitle(/ಪದLab.*Kannada Word Reading Assessment/);
  await expectFlutterMounted(page);

  const releaseResponse = await page.request.get("/app-release.json");
  expect(releaseResponse.status()).toBe(200);
  const release = await releaseResponse.json();
  expect(release.application).toBe("PadLab");
  expect(release.webRole).toBe("interactive_online_workspace");
  expect(release.participantDataEntry).toBe(false);
  expect(release.participantReady).toBe(false);
  expect(release.participantDataSync).toBe(false);
  if (process.env.GITHUB_SHA) {
    expect(release.commit).toBe(process.env.GITHUB_SHA);
  }

  const mainScript = await page.request.get("/main.dart.js");
  expect(mainScript.status()).toBe(200);
  expect((await mainScript.body()).byteLength).toBeGreaterThan(500_000);

  await page.waitForTimeout(1500);
  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);
});

test("desktop and mobile viewports mount the same Flutter application", async ({
  page,
}) => {
  const sizes = [
    { width: 320, height: 740 },
    { width: 360, height: 800 },
    { width: 390, height: 844 },
    { width: 430, height: 932 },
    { width: 480, height: 960 },
    { width: 600, height: 960 },
    { width: 768, height: 1024 },
    { width: 860, height: 900 },
    { width: 900, height: 900 },
    { width: 1024, height: 768 },
    { width: 1365, height: 900 },
    { width: 1920, height: 1080 },
  ];

  const initialResponse = await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(initialResponse).not.toBeNull();
  expect(initialResponse.status()).toBe(200);
  await expectFlutterMounted(page);

  for (const size of sizes) {
    await page.setViewportSize(size);
    await expect
      .poll(() => page.evaluate(() => window.innerWidth))
      .toBe(size.width);
    await expectFlutterMounted(page);

    await expectFlutterWidth(page, size.width);
    const viewport = await page.evaluate(() => ({
      width: window.innerWidth,
      height: window.innerHeight,
      documentWidth: Math.max(
        document.documentElement.scrollWidth,
        document.body.scrollWidth,
      ),
    }));
    expect(viewport.width).toBe(size.width);
    expect(viewport.height).toBe(size.height);
    expect(viewport.documentWidth).toBeLessThanOrEqual(size.width + 1);
  }
});

test("production Web assets contain the expected review-only study data", async ({
  request,
}) => {
  const candidatesResponse = await request.get(CANDIDATE_CSV);
  expect(candidatesResponse.status()).toBe(200);
  expect(candidatesResponse.headers()["content-type"]).toContain("text/csv");
  const candidates = await candidatesResponse.text();
  const candidateRows = candidates.trim().split(/\r?\n/);
  expect(candidateRows).toHaveLength(194); // header + 193 supplied rows
  expect(candidateRows[0]).toContain("nonword_id");
  expect(candidateRows[193]).toContain(",N270,");
  expect(candidates).toContain("pending_native_kannada_review");

  const allocationResponse = await request.get(ALLOCATION_JSON);
  expect(allocationResponse.status()).toBe(200);
  const allocation = await allocationResponse.json();
  expect(allocation.status).toBe(
    "engineering_draft_not_approved_for_participant_use",
  );
  expect(allocation.session_count).toBe(6);
  expect(allocation.real_words_per_session).toBe(45);
  expect(allocation.nonwords_per_session).toBe(32);
  expect(allocation.scored_items_per_session).toBe(77);
  expect(allocation.total_scored_items).toBe(462);
  expect(allocation.reserve_nonword_id).toBe("N270");
  expect(allocation.participant_workflow_enabled).toBe(false);
});

test("offline app-shell navigation works after first-install precache", async ({
  page,
  context,
}) => {
  const response = await page.goto("/", { waitUntil: "domcontentloaded" });
  expect(response).not.toBeNull();
  expect(response.status()).toBe(200);
  await expectFlutterMounted(page);

  const registrationReady = await page.evaluate(async () => {
    if (!("serviceWorker" in navigator)) return false;
    const registration = await navigator.serviceWorker.ready;
    return Boolean(registration.active);
  });
  expect(registrationReady).toBe(true);

  await expect
    .poll(
      () => page.evaluate(
        () => navigator.serviceWorker.controller !== null,
      ),
      { timeout: 15_000 },
    )
    .toBe(true);

  await context.setOffline(true);
  try {
    const offlineResponse = await page.reload({
      waitUntil: "domcontentloaded",
      timeout: 30_000,
    });
    expect(offlineResponse).not.toBeNull();
    expect(offlineResponse.status()).toBe(200);
    await expectFlutterMounted(page);
  } finally {
    await context.setOffline(false);
  }
});


test("Android Chrome renders at real phone viewport widths without horizontal overflow", async ({
  browser,
}) => {
  test.skip(
    browser.browserType().name() !== "chromium",
    "Android Chrome device emulation runs in the Google Chrome project.",
  );

  const phoneSizes = [
    { width: 320, height: 740 },
    { width: 360, height: 800 },
    { width: 375, height: 812 },
    { width: 390, height: 844 },
    { width: 412, height: 915 },
    { width: 430, height: 932 },
    { width: 480, height: 960 },
    { width: 844, height: 390 },
  ];

  for (const size of phoneSizes) {
    const context = await browser.newContext({
      viewport: size,
      screen: size,
      deviceScaleFactor: 2,
      isMobile: true,
      hasTouch: true,
      userAgent:
        "Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Mobile Safari/537.36",
    });

    try {
      const page = await context.newPage();
      const pageErrors = [];
      const consoleErrors = [];
      page.on("pageerror", (error) => pageErrors.push(error.message));
      page.on("console", (message) => {
        if (message.type() === "error") consoleErrors.push(message.text());
      });

      const response = await page.goto("/", { waitUntil: "domcontentloaded" });
      expect(response).not.toBeNull();
      expect(response.status()).toBe(200);
      await expectFlutterMounted(page);

      const metrics = await page.evaluate(() => ({
        innerWidth: Math.round(window.innerWidth),
        visualViewportWidth: Math.round(window.visualViewport?.width ?? 0),
        documentWidth: Math.max(
          document.documentElement.scrollWidth,
          document.body.scrollWidth,
        ),
        touchPoints: navigator.maxTouchPoints,
        viewport: document.querySelector('meta[name="viewport"]')?.getAttribute("content") ?? "",
      }));

      expect(metrics.innerWidth).toBe(size.width);
      expect(metrics.visualViewportWidth).toBe(size.width);
      expect(metrics.documentWidth).toBeLessThanOrEqual(size.width + 1);
      expect(metrics.touchPoints).toBeGreaterThan(0);
      expect(metrics.viewport).toMatch(/width\s*=\s*device-width/i);
      // Flutter rewrites the viewport meta tag after boot; the static build validator checks viewport-fit=cover.
      expect(metrics.viewport).not.toMatch(
        /user-scalable\s*=\s*no|maximum-scale\s*=\s*1(?:\.0+)?/i,
      );

      await expectFlutterWidth(page, size.width);

      await page.waitForTimeout(500);
      expect(pageErrors).toEqual([]);
      expect(consoleErrors).toEqual([]);
    } finally {
      await context.close();
    }
  }
});


test("WebKit mobile Safari profile renders phone viewports without overflow", async ({
  browser,
}) => {
  test.skip(
    browser.browserType().name() !== "webkit",
    "Mobile Safari engine coverage runs in the WebKit project.",
  );

  const phoneSizes = [
    { width: 320, height: 568 },
    { width: 375, height: 812 },
    { width: 390, height: 844 },
    { width: 402, height: 874 },
    { width: 430, height: 932 },
    { width: 844, height: 390 },
  ];

  for (const size of phoneSizes) {
    const context = await browser.newContext({
      viewport: size,
      screen: size,
      deviceScaleFactor: 3,
      isMobile: true,
      hasTouch: true,
      userAgent:
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
    });

    try {
      const page = await context.newPage();
      const pageErrors = [];
      const consoleErrors = [];
      page.on("pageerror", (error) => pageErrors.push(error.message));
      page.on("console", (message) => {
        if (message.type() === "error") consoleErrors.push(message.text());
      });

      const response = await page.goto("/", { waitUntil: "domcontentloaded" });
      expect(response).not.toBeNull();
      expect(response.status()).toBe(200);
      await expectFlutterMounted(page);

      const metrics = await page.evaluate(() => ({
        innerWidth: Math.round(window.innerWidth),
        visualViewportWidth: Math.round(window.visualViewport?.width ?? 0),
        documentWidth: Math.max(
          document.documentElement.scrollWidth,
          document.body.scrollWidth,
        ),
        touchPoints: navigator.maxTouchPoints,
        viewport:
          document
            .querySelector('meta[name="viewport"]')
            ?.getAttribute("content") ?? "",
      }));

      expect(metrics.innerWidth).toBe(size.width);
      expect(metrics.visualViewportWidth).toBe(size.width);
      expect(metrics.documentWidth).toBeLessThanOrEqual(size.width + 1);
      expect(metrics.touchPoints).toBeGreaterThan(0);
      expect(metrics.viewport).toMatch(/width\s*=\s*device-width/i);
      expect(metrics.viewport).not.toMatch(
        /user-scalable\s*=\s*no|maximum-scale\s*=\s*1(?:\.0+)?/i,
      );
      await expectFlutterWidth(page, size.width);

      await page.waitForTimeout(500);
      expect(pageErrors).toEqual([]);
      expect(consoleErrors).toEqual([]);
    } finally {
      await context.close();
    }
  }
});
