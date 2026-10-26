import { test, expect } from "@playwright/test";
import { mkdir } from "node:fs/promises";
import path from "node:path";

test("capture the real catalogue, mobile layout and review", async ({
  page,
}) => {
  const output = path.resolve("outputs");
  await mkdir(output, { recursive: true });
  const capture = (name) =>
    page.screenshot({ path: path.join(output, name), animations: "disabled" });
  await page.goto("/");
  await expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
  await capture("preview-desktop.png");
  await capture("preview-dark.png");
  await page.getByRole("radio", { name: "BRITX Choice", exact: true }).check();
  await expect(
    page.getByRole("checkbox", { name: "Visual Studio Code", exact: true }),
  ).toBeChecked();
  await expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
  await capture("preview-britx.png");
  await page
    .getByRole("button", { name: "Switch to light theme", exact: true })
    .click();
  await capture("preview-light.png");
  await page
    .getByRole("button", { name: "Switch to dark theme", exact: true })
    .click();
  await page.setViewportSize({ width: 390, height: 844 });
  await capture("preview-mobile.png");
  await page.locator(".catalog-panel").scrollIntoViewIfNeeded();
  await capture("preview-mobile-catalogue.png");
  await page.setViewportSize({ width: 1536, height: 1024 });
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  await expect(page.locator("#paid-notice")).toBeVisible();
  await capture("preview-review.png");
});

test("capture a completed isolated companion preview", async ({ page }) => {
  await page.goto("http://127.0.0.1:3420/#session=browser-test-session-only");
  await expect(
    page.getByText("Local companion · Dry-run preview", { exact: true }),
  ).toBeVisible();
  if (
    await page
      .getByRole("button", { name: "Return to choices", exact: true })
      .isVisible()
  ) {
    await page
      .getByRole("button", { name: "Return to choices", exact: true })
      .click();
  }
  await page.getByRole("radio", { name: "Essentials", exact: true }).check();
  for (const name of ["Figma MCP", "VMware Fusion"]) {
    await page.getByRole("searchbox").fill(name);
    await page.getByRole("checkbox", { name, exact: true }).check();
  }
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  await page
    .getByRole("checkbox", {
      name: "I’ve reviewed this setup and want to continue.",
    })
    .check();
  await page
    .getByRole("button", { name: "Start dry-run preview", exact: true })
    .click();
  await expect(
    page.getByRole("region", { name: "Guided installation" }),
  ).toBeVisible();
  await expect(page.locator("#progress-description")).toHaveText(
    "Preview finished. No apps or preferences were changed.",
    { timeout: 40000 },
  );
  await expect(
    page.getByRole("heading", { name: "Figma MCP", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("button", { name: "Download install report", exact: true }),
  ).toBeEnabled();
  await page.screenshot({
    path: path.resolve("outputs/preview-progress.png"),
    animations: "disabled",
  });
});
