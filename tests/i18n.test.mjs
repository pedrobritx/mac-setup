import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import messages from "../docs/assets/messages.mjs";
import { LANGUAGES, setLocale, translate } from "../docs/assets/i18n.mjs";

test("every catalogue description has four translations with intact template slots", () => {
  const sources = new Set();
  const slots = (value) =>
    [...value.matchAll(/\{\d+\}/g)].map(([slot]) => slot).sort();
  for (const [source, ...translations] of messages) {
    assert.ok(!sources.has(source), `Duplicate message: ${source}`);
    sources.add(source);
    assert.equal(translations.length, LANGUAGES.length - 1, source);
    for (const translation of translations) {
      assert.ok(translation.trim(), source);
      assert.deepEqual(slots(translation), slots(source), source);
    }
  }
  const catalog = JSON.parse(
    readFileSync(new URL("../docs/assets/catalog.json", import.meta.url)),
  );
  for (const item of catalog.items)
    assert.ok(sources.has(item.description), item.id);
});

test("specific phrases beat broad templates and English restores canonical wording", () => {
  const previousDocument = globalThis.document;
  // Translation itself also runs in Node; this minimal host has no rendered tree.
  globalThis.document = { documentElement: {}, body: null, dispatchEvent() {} };
  try {
    setLocale("pt-BR");
    assert.equal(
      translate(
        "Select all 36 items in Development, including items hidden by filters. Required prerequisites are included.",
      ),
      "Selecionar todos os 36 itens de Desenvolvimento, incluindo os ocultos pelos filtros. Os pré-requisitos obrigatórios são incluídos.",
    );
    assert.equal(
      translate("Select all Development"),
      "Selecionar tudo em Desenvolvimento",
    );
    assert.equal(translate("Verification"), "Verificação");
    assert.equal(
      translate("5 of 5 steps processed"),
      "5 de 5 etapas processadas",
    );
    assert.equal(translate("GitHub Desktop"), "GitHub Desktop");
    for (const { id } of LANGUAGES) {
      setLocale(id);
      assert.equal(translate("cask:docker-desktop"), "cask:docker-desktop");
    }
    setLocale("en-GB");
    assert.equal(translate("Select all Development"), "Select all Development");
    assert.throws(() => setLocale("unsupported"), /Unsupported language/);
  } finally {
    setLocale("en-GB");
    if (previousDocument === undefined) delete globalThis.document;
    else globalThis.document = previousDocument;
  }
});
