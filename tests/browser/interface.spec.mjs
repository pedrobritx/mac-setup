import { test, expect } from "@playwright/test";

const waitForCatalogue = async (page) =>
  expect(
    page.getByRole("radio", { name: "Essentials", exact: true }),
  ).toBeVisible();
const step = (page, name) =>
  page.locator(".stepper").getByRole("button", { name });
const brew =
  "brew install --formula mas; brew install --cask google-chrome appcleaner 1password vlc";

async function openHomebrewCommand(page) {
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  await page
    .getByRole("radio", { name: "Homebrew command", exact: true })
    .check();
  await page
    .getByRole("button", { name: "Show Homebrew command", exact: true })
    .click();
}

test("Copy falls back when the clipboard API is refused, then selects the command for ⌘C", async ({
  page,
}) => {
  // Embedded browsers can deny the async clipboard permission outright.
  await page.addInitScript(() => {
    window.copied = [];
    window.selectionCopyWorks = true;
    Object.defineProperty(navigator, "clipboard", {
      value: {
        writeText: () =>
          Promise.reject(new DOMException("Denied", "NotAllowedError")),
      },
    });
    const execCommand = document.execCommand.bind(document);
    document.execCommand = (command, ...rest) => {
      if (command !== "copy") return execCommand(command, ...rest);
      window.copied.push(document.activeElement?.value ?? "");
      return window.selectionCopyWorks;
    };
  });
  await page.goto("/");
  await waitForCatalogue(page);
  await openHomebrewCommand(page);
  await page.locator("#copy-brew-command").focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("#copy-brew-command")).toHaveText("Copied");
  await expect(page.locator("#copy-brew-command")).toBeFocused();
  expect(await page.evaluate(() => window.copied)).toEqual([brew]);

  await page.evaluate(() => {
    window.selectionCopyWorks = false;
  });
  await page.locator("#copy-app-store-command").click();
  await expect(page.locator("#copy-app-store-command")).toHaveText("Copy");
  await expect(
    page.getByRole("status").filter({ hasText: "press ⌘C" }),
  ).toBeVisible();
  expect(await page.evaluate(() => getSelection().toString())).toBe(
    "mas get 425424353",
  );
  await expect(page.locator("#app-error")).toBeHidden();
});

test("the language picker centres its flag, names languages only and opens below on every view", async ({
  page,
}) => {
  // At compact widths the summary floats; on later views it is hidden.
  await page.setViewportSize({ width: 923, height: 932 });
  await page.goto("/");
  await waitForCatalogue(page);
  const offset = await page.evaluate(() => {
    const circle = document
      .querySelector("#language-trigger")
      .getBoundingClientRect();
    const flag = document
      .querySelector("#language-trigger .language-flag")
      .getBoundingClientRect();
    return [
      circle.x + circle.width / 2 - (flag.x + flag.width / 2),
      circle.y + circle.height / 2 - (flag.y + flag.height / 2),
    ];
  });
  for (const delta of offset) expect(Math.abs(delta)).toBeLessThan(0.51);

  const list = page.locator("#language-options");
  for (const view of ["choose", "review", "command"]) {
    if (view === "review")
      await page
        .getByRole("button", { name: "Review setup", exact: true })
        .click();
    if (view === "command") {
      await page
        .getByRole("radio", { name: "Homebrew command", exact: true })
        .check();
      await page
        .getByRole("button", { name: "Show Homebrew command", exact: true })
        .click();
    }
    await page.locator("#language-trigger").click();
    await expect(list).toHaveAttribute("data-side", "below");
    await expect(list.getByRole("option")).toHaveText([
      "English",
      "Português",
      "Français",
      "Deutsch",
      "Español",
    ]);
    await expect
      .poll(async () => {
        const box = await list.boundingBox();
        return box.y >= 0 && box.y + box.height <= 932;
      })
      .toBe(true);
    await page.keyboard.press("Escape");
    await expect(list).not.toBeVisible();
  }
  await page.locator("#language-trigger").click();
  await list.getByRole("option", { name: "Português", exact: true }).click();
  await expect(page.locator("html")).toHaveAttribute("lang", "pt-BR");
});

test("stepper steps navigate between choices, review and the chosen route", async ({
  page,
}) => {
  await page.goto("/");
  await waitForCatalogue(page);
  await expect(step(page, /Choose & customise/)).toHaveAttribute(
    "aria-current",
    "step",
  );
  await step(page, /Review your setup/).click();
  await expect(page.locator("#review-view")).toBeVisible();
  await expect(step(page, /Review your setup/)).toHaveAttribute(
    "aria-current",
    "step",
  );

  // The guided handoff opens without downloading; its button offers the plan.
  let downloads = 0;
  page.on("download", () => downloads++);
  await step(page, /Guided installation/).click();
  await expect(
    page.getByRole("heading", { name: "A small handoff to your Mac." }),
  ).toBeVisible();
  await expect(page.locator("#download-again")).toHaveText("Download plan");
  expect(downloads).toBe(0);

  await step(page, /Review your setup/).focus();
  await page.keyboard.press("Enter");
  await expect(page.locator("#review-view")).toBeVisible();
  await page
    .getByRole("radio", { name: "Homebrew command", exact: true })
    .check();
  await step(page, /Homebrew command/).click();
  await expect(page.locator("#command-view")).toBeVisible();
  await step(page, /Choose & customise/).click();
  await expect(page.locator("#choose-view")).toBeVisible();
  await expect(step(page, /Choose & customise/)).toHaveAttribute(
    "aria-current",
    "step",
  );
});

test("the headline gradient glides on hover and back, and stays still when motion is reduced", async ({
  page,
}) => {
  await page.goto("/");
  await waitForCatalogue(page);
  const title = page.locator("#page-title .gradient-text");
  const stop = () =>
    title.evaluate((node) =>
      getComputedStyle(node).getPropertyValue("--title-stop-1").trim(),
    );
  const rest = await stop();
  await title.hover();
  await page.waitForTimeout(300);
  const between = await stop();
  await page.waitForTimeout(1200);
  const hovered = await stop();
  expect(hovered).not.toBe(rest);
  expect([rest, hovered]).not.toContain(between);
  await page.mouse.move(5, 5);
  await expect.poll(stop, { timeout: 3000 }).toBe(rest);

  await page.emulateMedia({ reducedMotion: "reduce" });
  await title.hover();
  await page.waitForTimeout(300);
  expect(await stop()).toBe(rest);
});
