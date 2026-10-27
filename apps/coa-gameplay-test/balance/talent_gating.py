CLI_DESCRIPTION = """Dump the real CoA talent gating data (AscensionCoATalentData) as JSON.

Compiles the same talent catalog loader apps/coa-tests/coa_talent_catalog.py uses against the client DBC
set the server loads (--dbc-dir or COA_DBC_DIR), and prints every CoATalentEntry (including RequiredEntryIds
and the tab investment thresholds SetTalentRank/ApplyKnownEntriesUpload gate on) plus every CoATalentBudget
row, as one JSON object. No database, server build or game client is needed.
"""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / "apps/coa-tests"))
from coa_talent_catalog import STUBS  # noqa: E402
from client_data import dbc_dir  # noqa: E402

MAIN = r"""
#include "AscensionCoATalentData.h"
#include "DBCStores.h"
#include <cstdio>

using namespace AscensionCompatData;

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    if (!LoadCoATalentData())
        return 1;
    std::puts("ENTRIES");
    for (CoATalentEntry const& e : CoATalentEntries)
        std::printf("%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\t%u\n", e.EntryId, e.ClassId, e.SpecId,
            e.SpellCount, e.AECost, e.TECost, e.RequiredLevel, e.TabAEInvestment, e.TabTEInvestment,
            e.RequiredEntryIds[0], e.RequiredEntryIds[1], e.RequiredEntryIds[2]);
    std::puts("BUDGETS");
    for (CoATalentBudget const& b : CoATalentBudgets)
        std::printf("%u\t%u\t%u\t%u\n", unsigned(b.ClassId), unsigned(b.Level), unsigned(b.AE), unsigned(b.TE));
    return 0;
}
"""


ITEM_MOD_STUB = """#pragma once
enum ItemModType
{
    ITEM_MOD_AGILITY = 3,
    ITEM_MOD_STRENGTH = 4,
    ITEM_MOD_INTELLECT = 5,
    ITEM_MOD_SPIRIT = 6,
    ITEM_MOD_STAMINA = 7,
};
"""


def _compile(out):
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    for name, text in STUBS.items():
        (out / name).write_text(text, encoding="utf-8")
    (out / "ItemTemplate.h").write_text(ITEM_MOD_STUB, encoding="utf-8")
    (out / "main.cpp").write_text(MAIN, encoding="utf-8")
    includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores", ROOT / "src/common"]
    sources = [out / "main.cpp", ROOT / "src/server/coa/AscensionCoATalentData.cpp",
               ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
    executable = out / ("dump.exe" if os.name == "nt" else "dump")
    if Path(compiler).stem.lower() == "cl":
        flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                 *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
    else:
        flags = ["-std=c++20", *["-I" + str(p) for p in includes], *map(str, sources), "-o", str(executable)]
    build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
    if build.returncode:
        raise RuntimeError("Talent gating dumper did not compile:\n" + build.stdout + build.stderr)
    return executable


def dump_gating(dbc_directory):
    with tempfile.TemporaryDirectory(prefix="coa-talent-gating-") as directory:
        out = Path(directory)
        executable = _compile(out)
        text = subprocess.run([str(executable), str(Path(dbc_directory).resolve())], check=True,
                              capture_output=True, text=True).stdout

    lines = text.splitlines()
    entries = []
    budgets = []
    section = None
    for line in lines:
        if line == "ENTRIES":
            section = entries
            continue
        if line == "BUDGETS":
            section = budgets
            continue
        if section is None:
            continue
        section.append([int(field) for field in line.split("\t")])

    gating = {
        "entries": [
            {
                "entry": row[0],
                "class_id": row[1],
                "spec_id": row[2],
                "spell_count": row[3],
                "ae_cost": row[4],
                "te_cost": row[5],
                "required_level": row[6],
                "tab_ae_investment": row[7],
                "tab_te_investment": row[8],
                "required_entry_ids": [value for value in row[9:12] if value],
            }
            for row in entries
        ],
        "budgets": [
            {"class_id": row[0], "level": row[1], "ae": row[2], "te": row[3]}
            for row in budgets
        ],
    }
    return gating


def budget_at(budgets, class_id, level):
    best = None
    for row in budgets:
        if row["class_id"] != class_id or row["level"] > level:
            continue
        if best is None or row["level"] > best["level"]:
            best = row
    return (best["ae"], best["te"]) if best else (0, 0)


def validate_build(gating, class_id, spec_id, level, build):
    by_id = {e["entry"]: e for e in gating["entries"]}
    ae_budget, te_budget = budget_at(gating["budgets"], class_id, level)
    spent_ae = 0
    spent_te = 0
    accepted_ids = set()
    tier_spend_ae = []
    tier_spend_te = []

    for entry_id, rank in build:
        entry = by_id.get(entry_id)
        if entry is None:
            return f"entry {entry_id} does not exist"
        if entry["class_id"] != class_id:
            return f"entry {entry_id} does not belong to class {class_id}"
        if entry["spec_id"] not in (0, spec_id):
            return f"entry {entry_id} belongs to specialization {entry['spec_id']}, not {spec_id}"
        if entry_id in accepted_ids:
            return f"entry {entry_id} repeats in the uploaded build"
        if rank <= 0 or rank > entry["spell_count"]:
            return f"entry {entry_id} rank {rank} is outside its {entry['spell_count']} rank(s)"
        if entry["required_level"] > level:
            return f"entry {entry_id} requires level {entry['required_level']}, build is for level {level}"

        class_tree = entry["spec_id"] == 0
        threshold = entry["tab_ae_investment"] if class_tree else entry["tab_te_investment"]
        tiers = tier_spend_ae if class_tree else tier_spend_te
        invested = sum(cost for cost, tier in tiers if tier < threshold)
        if threshold and invested < threshold:
            return f"entry {entry_id} needs {threshold} point(s) invested below its tier, has {invested}"

        for required_id in entry["required_entry_ids"]:
            required = by_id.get(required_id)
            if required and (required["ae_cost"] or required["te_cost"]) and required_id not in accepted_ids:
                return f"entry {entry_id} requires entry {required_id}, not yet in the build"

        cost_per_rank = entry["ae_cost"] or entry["te_cost"]
        cost = cost_per_rank * rank
        budget = ae_budget if class_tree else te_budget
        spent = spent_ae if class_tree else spent_te
        if spent + cost > budget:
            return f"entry {entry_id} rank {rank} needs {cost}; {spent} of {budget} already spent"

        if class_tree:
            spent_ae += cost
        else:
            spent_te += cost
        accepted_ids.add(entry_id)
        tiers.append((cost, threshold))

    return None


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    gating = dump_gating(args.dbc_dir)
    text = json.dumps(gating, indent=2)
    if args.output:
        args.output.write_text(text + "\n", encoding="utf-8")
    else:
        print(text)


if __name__ == "__main__":
    main()
