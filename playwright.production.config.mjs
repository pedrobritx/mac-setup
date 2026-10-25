import { defineConfig } from "@playwright/test";
import base from "./playwright.config.mjs";

const site = new URL(
  process.env.MAC_SETUP_SITE_URL || "https://mac-setup.britx.me/",
);
const localOrigin = "http://127.0.0.1:3419";
const productionOrigin = "https://mac-setup.britx.me";
if (
  ![localOrigin, productionOrigin].includes(site.origin) ||
  site.pathname !== "/" ||
  site.search ||
  site.hash ||
  site.username ||
  site.password
)
  throw new Error("Use the production origin or the isolated local rehearsal.");

// An optional development proxy must not relax HTTPS certificate verification.
const proxy = process.env.MAC_SETUP_TEST_PROXY;
if (proxy) {
  const url = new URL(proxy);
  if (
    !["http:", "https:"].includes(url.protocol) ||
    url.username ||
    url.password ||
    url.pathname !== "/" ||
    url.search ||
    url.hash
  )
    throw new Error(
      "The test proxy must be an HTTP(S) URL without credentials.",
    );
}

export default defineConfig({
  ...base,
  testDir: "./tests/acceptance",
  outputDir: "test-results/production",
  reporter: [
    ["list", { printSteps: true }],
    ["json", { outputFile: "test-results/production/results.json" }],
    ["html", { outputFolder: "playwright-report/production", open: "never" }],
  ],
  metadata: {
    target: site.origin,
    mode: site.origin === localOrigin ? "local-rehearsal" : "production",
    expectedCommit:
      process.env.MAC_SETUP_EXPECTED_COMMIT ||
      process.env.GITHUB_SHA ||
      "working-tree",
    proxied: Boolean(proxy),
  },
  use: {
    ...base.use,
    baseURL: site.href,
    ...(proxy
      ? { proxy: { server: proxy, bypass: "127.0.0.1,localhost" } }
      : {}),
  },
  webServer: [
    ...(site.origin === localOrigin ? [base.webServer[0]] : []),
    base.webServer[1],
  ],
});
