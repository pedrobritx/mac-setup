import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import { readFile } from "node:fs/promises";

const waitForCatalogue = async (page) =>
  expect(
    page.getByRole("radio", { name: "Essentials", exact: true }),
  ).toBeVisible();

test("profiles, search, source filters, prerequisites and persistence remain editable", async ({
  page,
}) => {
  await page.goto("/");
  await waitForCatalogue(page);
  await page.getByRole("radio", { name: "Developer", exact: true }).check();
  await page.getByRole("searchbox").fill("Python");
  await expect(
    page.getByRole("checkbox", { name: "Python", exact: true }),
  ).toBeChecked();
  await page.getByRole("checkbox", { name: "Python", exact: true }).uncheck();
  await page.reload();
  await waitForCatalogue(page);
  await page.getByRole("searchbox").fill("Python");
  await expect(
    page.getByRole("checkbox", { name: "Python", exact: true }),
  ).not.toBeChecked();
  await page.getByRole("checkbox", { name: "Python", exact: true }).check();
  await page.getByRole("searchbox").fill("uv");
  await expect(
    page.getByRole("checkbox", { name: "uv", exact: true }),
  ).toBeChecked();
  await page.getByRole("checkbox", { name: "uv", exact: true }).uncheck();
  await page.getByRole("searchbox").fill("Python");
  await expect(
    page.getByRole("checkbox", { name: "Python", exact: true }),
  ).not.toBeChecked();
  await page.getByRole("searchbox").fill("");
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
  await page.getByRole("searchbox").fill("no-such-app-1234");
  await expect(
    page.getByRole("heading", { name: "Nothing here yet." }),
  ).toBeVisible();
  await page
    .getByRole("button", { name: "Reset filters", exact: true })
    .click();
  await expect(
    page.getByRole("checkbox", { name: "Visual Studio Code", exact: true }),
  ).toBeVisible();
});

test("public plan download imports into the real companion and runs an isolated dry run", async ({
  page,
}, testInfo) => {
  await page.goto("/");
  await waitForCatalogue(page);
  await page.getByRole("searchbox").fill("Figma MCP");
  await page.getByRole("checkbox", { name: "Figma MCP", exact: true }).check();
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  const downloadPromise = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Download plan & continue", exact: true })
    .click();
  const download = await downloadPromise;
  const path = testInfo.outputPath("mac-setup-plan.json");
  await download.saveAs(path);
  const plan = JSON.parse(await readFile(path, "utf8"));
  expect(plan.selected).toContain("mcp:figma");
  expect(Object.keys(plan)).toEqual([
    "schema",
    "catalogVersion",
    "profile",
    "selected",
  ]);
  await expect(
    page.getByRole("heading", { name: "A small handoff to your Mac." }),
  ).toBeVisible();
  await page.goto("http://127.0.0.1:3420/#session=browser-test-session-only");
  await expect(
    page.getByText("Local companion · Dry-run preview", { exact: true }),
  ).toBeVisible();
  await page.locator("#plan-file").setInputFiles(path);
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  await expect(
    page.getByRole("button", { name: "Start dry-run preview", exact: true }),
  ).toBeDisabled();
  await page
    .getByRole("checkbox", {
      name: "I’ve reviewed this setup and want to continue.",
    })
    .check();
  await page
    .getByRole("button", { name: "Start dry-run preview", exact: true })
    .click();
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
  await expect(
    page.getByRole("button", { name: "Download install report", exact: true }),
  ).toBeEnabled();
  const reportPromise = page.waitForEvent("download");
  await page
    .getByRole("button", { name: "Download install report", exact: true })
    .click();
  const report = await reportPromise;
  const reportPath = testInfo.outputPath("install-report.md");
  await report.saveAs(reportPath);
  expect(await readFile(reportPath, "utf8")).toContain("**Mode:** dry-run");
  await page.route("**/api/state", (route) => route.abort());
  await page.reload();
  await expect(
    page
      .getByRole("alert")
      .filter({ hasText: "local companion could not connect" }),
  ).toBeVisible();
  await page.unroute("**/api/state");
});

test("BRITX labels paid apps and MCP setup honestly, with keyboard operable details", async ({
  page,
}) => {
  await page.goto("/");
  await waitForCatalogue(page);
  await page.getByRole("radio", { name: "BRITX Choice", exact: true }).check();
  await page.getByRole("searchbox").fill("Xcode");
  await page.getByRole("button", { name: /About Xcode$/ }).click();
  await expect(
    page.getByRole("link", { name: "View official source" }),
  ).toHaveAttribute(
    "href",
    "https://apps.apple.com/app/id497799835?platform=mac",
  );
  await page.keyboard.press("Escape");
  await page.getByRole("searchbox").fill("Stripe MCP");
  await page.getByRole("button", { name: /About Stripe MCP/ }).click();
  await expect(page.getByRole("dialog")).toContainText(
    "No tokens or agent configuration files are written automatically.",
  );
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).not.toBeVisible();
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  await expect(page.locator("#paid-notice")).toContainText("Final Cut Pro");
  await expect(page.locator("#paid-notice")).toContainText(
    "mac-setup will not purchase them",
  );
});

test("desktop and mobile have no horizontal overflow and meet automated WCAG checks in both themes", async ({
  page,
}) => {
  for (const viewport of [
    { width: 1536, height: 1024 },
    { width: 923, height: 932 },
    { width: 390, height: 844 },
  ]) {
    await page.setViewportSize(viewport);
    await page.goto("/");
    await waitForCatalogue(page);
    await expect(
      page.getByRole("button", { name: "Review setup", exact: true }),
    ).toBeInViewport();
    for (const mode of ["light", "dark"]) {
      if ((await page.locator("html").getAttribute("data-theme")) !== mode)
        await page
          .getByRole("button", { name: `Switch to ${mode} theme`, exact: true })
          .click();
      expect(
        await page.evaluate(
          () => document.documentElement.scrollWidth <= window.innerWidth,
        ),
      ).toBe(true);
      const results = await new AxeBuilder({ page })
        .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
        .analyze();
      expect(
        results.violations.map((v) => ({
          id: v.id,
          targets: v.nodes.map((n) => n.target),
        })),
      ).toEqual([]);
    }
    await page
      .getByRole("button", { name: "Review setup", exact: true })
      .click();
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= window.innerWidth,
      ),
    ).toBe(true);
    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
      .analyze();
    expect(
      results.violations.map((v) => ({
        id: v.id,
        targets: v.nodes.map((n) => n.target),
      })),
    ).toEqual([]);
  }
});
