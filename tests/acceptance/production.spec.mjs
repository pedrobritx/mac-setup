import { test, expect } from "@playwright/test";
import { readFile } from "node:fs/promises";

const ready = (page) =>
  expect(
    page.getByRole("radio", { name: "Essentials", exact: true }),
  ).toBeVisible();

// Export from the real public UI; server-side validation happens at handoff.
async function exportPlan(page, testInfo) {
  await page.goto("/");
  await ready(page);
  await page.getByRole("searchbox").fill("Figma MCP");
  await page.getByRole("checkbox", { name: "Figma MCP", exact: true }).check();
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  await expect(page.locator("#continue-button")).toHaveText(
    "Download plan & continue",
  );
  const pending = page.waitForEvent("download");
  await page.locator("#continue-button").click();
  const download = await pending;
  const file = testInfo.outputPath("production-plan.json");
  await download.saveAs(file);
  const plan = JSON.parse(await readFile(file, "utf8"));
  expect(Object.keys(plan)).toEqual([
    "schema",
    "catalogVersion",
    "profile",
    "selected",
  ]);
  expect(plan.selected).toContain("mcp:figma");
  return { file, plan };
}

test("published pages and runtime assets match the checked-out deployment", async ({
  request,
  baseURL,
}) => {
  for (const asset of [
    "index.html",
    "safety.html",
    "assets/catalog.json",
    "assets/liquid.mjs",
    "assets/app.mjs",
  ]) {
    await test.step(asset, async () => {
      const response = await request.get(new URL(asset, baseURL).href, {
        headers: { "Cache-Control": "no-cache" },
        timeout: 15000,
      });
      expect(response.status()).toBe(200);
      expect(await response.body()).toEqual(await readFile("docs/" + asset));
    });
  }
});

test("the public site filters, exports, imports and opens Safety without installing", async ({
  page,
}, testInfo) => {
  const errors = [];
  const mutations = [];
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("request", (request) => {
    if (!["GET", "HEAD"].includes(request.method()))
      mutations.push({ method: request.method(), url: request.url() });
  });

  await page.goto("/");
  await ready(page);
  await page
    .getByRole("button", { name: "Source All sources", exact: true })
    .click();
  await page.getByRole("option", { name: "App Store", exact: true }).click();
  await expect(
    page.getByRole("checkbox", { name: "Slack", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("checkbox", { name: "Visual Studio Code", exact: true }),
  ).toHaveCount(0);

  const { file, plan } = await exportPlan(page, testInfo);
  await expect(
    page.getByRole("heading", { name: "A small handoff to your Mac." }),
  ).toBeVisible();
  await page.goto("/safety.html");
  await expect(page.locator("#main h1")).toContainText("Your Mac.");
  await page.goto("/");
  await ready(page);
  await page.getByRole("searchbox").fill("Figma MCP");
  await expect(
    page.getByRole("checkbox", { name: "Figma MCP", exact: true }),
  ).toBeChecked();
  // Returning from Safety preserves the plan. Import must also work from a
  // different starting selection, rather than succeeding on saved state alone.
  await page.evaluate(() => localStorage.removeItem("mac-setup.plan.v1"));
  await page.reload();
  await ready(page);
  await page.getByRole("searchbox").fill("Figma MCP");
  await expect(
    page.getByRole("checkbox", { name: "Figma MCP", exact: true }),
  ).not.toBeChecked();
  await page.locator("#plan-file").setInputFiles(file);
  await expect(
    page.getByRole("checkbox", { name: "Figma MCP", exact: true }),
  ).toBeChecked();
  const persisted = JSON.parse(
    await page.evaluate(() => localStorage.getItem("mac-setup.plan.v1")),
  );
  expect(persisted.selected).toEqual(plan.selected);
  expect(errors).toEqual([]);
  expect(mutations).toEqual([]);
});

test("a public export completes only an isolated local dry run and downloads its report", async ({
  page,
}, testInfo) => {
  const { file } = await exportPlan(page, testInfo);
  await page.goto("http://127.0.0.1:3420/#session=browser-test-session-only");
  expect(new URL(page.url()).origin).toBe("http://127.0.0.1:3420");
  await expect(
    page.getByText("Local companion · Dry-run preview", { exact: true }),
  ).toBeVisible();
  await page.locator("#plan-file").setInputFiles(file);
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  const start = page.getByRole("button", {
    name: "Start dry-run preview",
    exact: true,
  });
  await expect(start).toBeDisabled();
  await page.locator("#confirm-install").check();
  await start.click();
  await expect(
    page
      .getByRole("region", { name: "Guided installation" })
      .getByText("Preview finished. No apps or preferences were changed.", {
        exact: true,
      }),
  ).toBeVisible({ timeout: 40000 });
  await expect(
    page.getByRole("heading", { name: "Figma MCP", exact: true }),
  ).toBeVisible();
  const pending = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Download install report", exact: true })
    .click();
  const report = await pending;
  const reportFile = testInfo.outputPath("production-handoff-report.md");
  await report.saveAs(reportFile);
  expect(await readFile(reportFile, "utf8")).toContain("**Mode:** dry-run");
});
