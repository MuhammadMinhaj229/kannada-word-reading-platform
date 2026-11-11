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
    { width: 1365, height: 900 },
    { width: 390, height: 844 },
  ];

  for (const size of sizes) {
    await page.setViewportSize(size);
    const response = await page.goto("/", { waitUntil: "domcontentloaded" });
    expect(response).not.toBeNull();
    expect(response.status()).toBe(200);
    await expectFlutterMounted(page);

    const viewport = await page.evaluate(() => ({
      width: window.innerWidth,
      height: window.innerHeight,
    }));
    expect(viewport).toEqual(size);
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

test("offline app-shell navigation works after the service worker takes control", async ({
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

  // The worker intentionally does not claim the first open page. Reload once
  // so the browser attaches the active worker before simulating offline mode.
  await page.reload({ waitUntil: "domcontentloaded" });
  await expectFlutterMounted(page);
  const controlled = await page.evaluate(
    () => navigator.serviceWorker.controller !== null,
  );
  expect(controlled).toBe(true);

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
