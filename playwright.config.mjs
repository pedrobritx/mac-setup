import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/browser",
  fullyParallel: false,
  workers: 1,
  timeout: 60000,
  retries: 0,
  reporter: [
    ["list", { printSteps: true }],
    ["json", { outputFile: "test-results/results.json" }],
    ["html", { outputFolder: "playwright-report", open: "never" }],
  ],
  use: {
    baseURL: "http://127.0.0.1:3419",
    viewport: { width: 1536, height: 1024 },
    browserName: "webkit",
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  webServer: [
    {
      command: "python3 -m http.server 3419 --bind 127.0.0.1 --directory docs",
      url: "http://127.0.0.1:3419",
      reuseExistingServer: false,
    },
    {
      command: "python3 tests/browser/companion.py",
      url: "http://127.0.0.1:3420/health",
      reuseExistingServer: false,
    },
  ],
});
