const { defineConfig } = require("@playwright/test");

module.exports = defineConfig({
  testDir: ".",
  testMatch: "**/*.spec.cjs",
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: 0,
  workers: 1,
  reporter: "list",
  timeout: 45_000,
  expect: {
    timeout: 15_000,
  },
  use: {
    baseURL: process.env.PADLAB_WEB_BASE_URL || "http://127.0.0.1:4173",
    headless: true,
    viewport: { width: 1365, height: 900 },
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    serviceWorkers: "allow",
  },
  projects: [
    {
      name: "google-chrome",
      use: {
        browserName: "chromium",
        channel: "chrome",
      },
    },
    {
      name: "webkit-safari",
      use: {
        browserName: "webkit",
      },
    },
    {
      name: "firefox",
      use: {
        browserName: "firefox",
      },
    },
  ],
});
