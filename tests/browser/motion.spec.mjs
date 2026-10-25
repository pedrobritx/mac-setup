import { test, expect } from "@playwright/test";

// Recording is an explicit QA mode; functional CI does not depend on encoding video.
// The page fixture owns cleanup, so a close error cannot replace a body failure.
test.use({
  video:
    process.env.MAC_SETUP_RECORD_VIDEO === "1"
      ? { mode: "on", size: { width: 1280, height: 854 } }
      : "off",
});

test("rapid selection changes settle on the final choice across the liquid interface", async ({
  page,
}) => {
  const profiles = page.locator("#profiles");

  await test.step("Open the setup and wait for its initial selection", async () => {
    await page.goto("/");
    await expect(profiles).toHaveAttribute("data-liquid-state", "settled");
  });

  await test.step("Rapid profile changes settle on BRITX Choice", async () => {
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
  });

  await test.step("The guide responds to hover, opens and dismisses", async () => {
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
  });

  await test.step("Source and category controls settle without blocking details", async () => {
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
  });

  await test.step("Review and return preserve an editable final selection", async () => {
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
  });
});
