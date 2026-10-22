import { test, expect } from "@playwright/test";
import path from "node:path";

test("rapid selection changes settle on the final choice and record the real liquid interface", async ({
  browser,
}) => {
  const context = await browser.newContext({
    viewport: { width: 1536, height: 1024 },
    recordVideo: {
      dir: path.resolve("test-results/liquid-video"),
      size: { width: 1280, height: 854 },
    },
  });
  const page = await context.newPage();
  const video = page.video();
  try {
    await page.goto("http://127.0.0.1:3419/");
    const profiles = page.locator("#profiles");
    await expect(profiles).toHaveAttribute("data-liquid-state", "settled");
    await page.getByRole("radio", { name: "Developer", exact: true }).check();
    await expect(profiles).toHaveAttribute("data-liquid-state", "moving");
    await page.getByRole("radio", { name: "Education", exact: true }).check();
    await page
      .getByRole("radio", { name: "BRITX Choice", exact: true })
      .check();
    await expect(profiles).toHaveAttribute("data-liquid-state", "settled");
    await expect(
      page.getByRole("radio", { name: "BRITX Choice", exact: true }),
    ).toBeChecked();
    const how = page.getByRole("button", { name: "How it works", exact: true });
    await how.hover();
    await expect
      .poll(() =>
        how.evaluate((node) => getComputedStyle(node, "::before").opacity),
      )
      .toBe("1");
    await how.click();
    await expect(page.getByRole("dialog")).toHaveCSS("opacity", "1");
    await page
      .getByRole("button", { name: "Close details", exact: true })
      .click();
    await expect(page.getByRole("dialog")).not.toBeVisible();
    const source = page.getByRole("button", {
      name: "Source All sources",
      exact: true,
    });
    await source.click();
    await expect(page.getByRole("listbox")).toHaveCSS("opacity", "1");
    await page.keyboard.press("Escape");
    await page
      .locator("#categories")
      .getByRole("button", { name: "AI & design", exact: true })
      .click();
    await expect(page.locator("#categories")).toHaveAttribute(
      "data-liquid-state",
      "settled",
    );
    await page.getByRole("button", { name: /About Figma$/ }).click();
    await expect(page.getByRole("dialog")).toHaveCSS("opacity", "1");
    await page
      .getByRole("button", { name: "Close details", exact: true })
      .click();
    await expect(page.getByRole("dialog")).not.toBeVisible();
    await page.mouse.wheel(0, 320);
    await expect
      .poll(() => page.evaluate(() => window.scrollY))
      .toBeGreaterThan(0);
    await page
      .getByRole("button", { name: "Review setup", exact: true })
      .click();
    await page.locator("#export-button").hover();
    const back = page.getByRole("button", {
      name: "Back to choices",
      exact: true,
    });
    await back.hover();
    await expect
      .poll(() =>
        back.evaluate((node) => getComputedStyle(node, "::before").opacity),
      )
      .toBe("1");
    await back.click();
    await page.getByRole("radio", { name: "Essentials", exact: true }).check();
    await expect(profiles).toHaveAttribute("data-liquid-state", "settled");
  } finally {
    await context.close();
  }
  await video.saveAs(path.resolve("outputs/liquid-preview.webm"));
});
