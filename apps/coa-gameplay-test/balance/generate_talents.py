CLI_DESCRIPTION = """Regenerate apps/coa-gameplay-test/balance/catalog.json's talents against real gating data.

Reads the live AscensionCoATalentData gating (talent_gating.dump_gating), then for every spec not already
carrying a build sourced from an external recon, computes a deterministic spend per level that respects
RequiredLevel, RequiredEntryIds, the TabAEInvestment/TabTEInvestment tier gates and the class/specialization
AE/TE budgets ApplyKnownEntriesUpload (AscensionCompat.cpp) enforces, then writes the result back into
catalog.json in tier-ascending order, so the balance suite's own incremental per-step upload stays valid at
every step, not only once the whole build is known.
"""

import argparse
from pathlib import Path
import json
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from talent_gating import dump_gating  # noqa: E402
sys.path.insert(0, str(HERE.parents[1] / "coa-tests"))
from client_data import dbc_dir  # noqa: E402

CATALOG_PATH = HERE / "catalog.json"
LEVELS = (20, 40, 60)
EXTERNAL_BUILD_SPECS = {(23, 34), (23, 35), (23, 36)}


def budget_at(budgets, class_id, level):
    best = None
    for row in budgets:
        if row["class_id"] != class_id or row["level"] > level:
            continue
        if best is None or row["level"] > best["level"]:
            best = row
    return (best["ae"], best["te"]) if best else (0, 0)


def candidates_for(entries, class_id, spec_id):
    return [e for e in entries if e["class_id"] == class_id and (e["ae_cost"] or e["te_cost"]) and
            (e["spec_id"] == 0 or e["spec_id"] == spec_id)]


def spend_build(entries, budgets, class_id, spec_id, level):
    pool = [e for e in candidates_for(entries, class_id, spec_id) if e["required_level"] <= level]
    pool.sort(key=lambda e: (0 if e["spec_id"] == 0 else 1, e["tab_ae_investment"] if e["spec_id"] == 0
                             else e["tab_te_investment"], e["entry"]))
    ae_budget, te_budget = budget_at(budgets, class_id, level)
    paid_entry_ids = {e["entry"] for e in candidates_for(entries, class_id, spec_id)}

    spent_ae = 0
    spent_te = 0
    accepted = []
    accepted_ids = set()
    tier_spend_ae = []
    tier_spend_te = []

    def invested_below(tiers, threshold):
        return sum(cost for cost, tier in tiers if tier < threshold)

    for entry in pool:
        class_tree = entry["spec_id"] == 0
        threshold = entry["tab_ae_investment"] if class_tree else entry["tab_te_investment"]
        tiers = tier_spend_ae if class_tree else tier_spend_te
        if threshold and invested_below(tiers, threshold) < threshold:
            continue
        required_paid = [r for r in entry["required_entry_ids"] if r in paid_entry_ids]
        if any(r not in accepted_ids for r in required_paid):
            continue

        cost_per_rank = entry["ae_cost"] or entry["te_cost"]
        budget = ae_budget if class_tree else te_budget
        spent = spent_ae if class_tree else spent_te
        max_affordable_rank = min(entry["spell_count"], (budget - spent) // cost_per_rank if cost_per_rank else 0)
        if max_affordable_rank <= 0:
            continue

        cost = max_affordable_rank * cost_per_rank
        if class_tree:
            spent_ae += cost
        else:
            spent_te += cost
        accepted.append((entry["entry"], max_affordable_rank))
        accepted_ids.add(entry["entry"])
        tiers.append((cost, threshold))

    return accepted


def regenerate(gating):
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    changed = []
    for spec in catalog["specs"]:
        key = (spec["class_id"], spec["spec_id"])
        if key in EXTERNAL_BUILD_SPECS:
            continue
        talents = {}
        for level in LEVELS:
            build = spend_build(gating["entries"], gating["budgets"], spec["class_id"], spec["spec_id"], level)
            talents[str(level)] = [[entry, rank] for entry, rank in build]
        spec["talents"] = talents
        changed.append(key)
    CATALOG_PATH.write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")
    return changed


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    parser.add_argument("--gating", type=Path, help="Reuse a previously dumped gating JSON instead of recompiling.")
    args = parser.parse_args()

    gating = json.loads(args.gating.read_text(encoding="utf-8")) if args.gating else \
        dump_gating(args.dbc_dir or dbc_dir())
    changed = regenerate(gating)
    print(f"Regenerated talents for {len(changed)} specs; preserved {len(EXTERNAL_BUILD_SPECS)} external builds.")


if __name__ == "__main__":
    main()
