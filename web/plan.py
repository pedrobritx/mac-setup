"""Validate untrusted browser plans and compile only allowlisted picker keys."""

import json
from pathlib import Path


class PlanError(ValueError):
    """A plan cannot be safely or faithfully executed."""


def validate_plan(plan, catalog):
    """Reject drift, injected keys, malformed input and missing prerequisites."""
    if not isinstance(plan, dict) or set(plan) != {"schema", "catalogVersion", "profile", "selected"}:
        raise PlanError("This is not a mac-setup plan. Export it again from the catalogue.")
    if type(plan["schema"]) is not int or plan["schema"] != 1:
        raise PlanError("Unsupported plan version. Export a new plan.")
    if plan["catalogVersion"] != catalog["version"]:
        raise PlanError("The catalogue has changed. Import this plan into the latest catalogue and review it again.")
    if not isinstance(plan["profile"], str) or plan["profile"] not in {p["id"] for p in catalog["profiles"]}:
        raise PlanError("Unknown setup profile.")
    selected = plan["selected"]
    if not isinstance(selected, list) or len(selected) > len(catalog["items"]) or any(not isinstance(k, str) for k in selected):
        raise PlanError("Selected items must be a list of catalogue IDs.")
    keys = set(selected)
    if len(keys) != len(selected):
        raise PlanError("The plan contains duplicate items.")
    items = {item["id"]: item for item in catalog["items"]}
    if not keys <= items.keys():
        raise PlanError("The plan contains items outside the catalogue.")
    for item in items.values():
        if item["locked"] and item["id"] not in keys:
            raise PlanError(f"{item['name']} is required.")
        if item["id"] in keys and not set(item["dependencies"]) <= keys:
            raise PlanError(f"Review prerequisites for {item['name']}.")
    return [item for item in catalog["items"] if item["id"] in keys]


def compile_selection(plan, catalog, destination):
    """Write data-only selection keys. Package arguments remain in the Brewfile."""
    items = validate_plan(plan, catalog)
    Path(destination).write_text("".join(item["id"] + "\n" for item in items
                                         if item["type"] in {"brew", "cask", "mas", "step", "pref"}))
    return items


def load_plan(path, catalog):
    if Path(path).stat().st_size > 65536:
        raise PlanError("Plan is too large.")
    try:
        plan = json.loads(Path(path).read_text())
    except (ValueError, UnicodeError) as error:
        raise PlanError("The plan is not valid JSON.") from error
    validate_plan(plan, catalog)
    return plan
