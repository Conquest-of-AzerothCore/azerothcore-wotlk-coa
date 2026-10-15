CLI_DESCRIPTION = """Check the stock spell-script shapes restored over Ascension's Spell.dbc, without a server.

Compiles AscensionStockScriptShapes.h and checks every restore against the Spell.dbc the server loads (--dbc-dir):
each one names a real spell and effect slot, and that slot still has the broken shape the restore is written
for, so no restore silently stops applying when the client data changes.
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

MAIN = r"""
#include "AscensionStockScriptShapes.h"
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iterator>
#include <map>
#include <string>
#include <utility>
#include <vector>

using namespace AscensionStockScriptShapes;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

constexpr std::size_t SPELL_EFFECT = 71;
constexpr std::size_t SPELL_TARGET_A = 86;
constexpr std::size_t SPELL_AURA = 95;
constexpr std::size_t SPELL_DESCRIPTION = 170;
}

int main(int, char** argv)
{
    std::ifstream file(std::string(argv[1]) + "/Spell.dbc", std::ios::binary);
    std::vector<char> data((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    Check(data.size() > 20 && std::memcmp(data.data(), "WDBC", 4) == 0, "Spell.dbc loads");
    if (failures)
        return 1;
    std::uint32_t count = 0, size = 0, fields = 0;
    std::memcpy(&count, data.data() + 4, 4);
    std::memcpy(&fields, data.data() + 8, 4);
    std::memcpy(&size, data.data() + 12, 4);
    char const* strings = data.data() + 20 + std::size_t(count) * size;
    std::map<std::uint32_t, char const*> rows;
    for (std::uint32_t row = 0; row < count; ++row)
    {
        char const* record = data.data() + 20 + std::size_t(row) * size;
        std::uint32_t id = 0;
        std::memcpy(&id, record, 4);
        rows[id] = record;
    }
    auto const field = [](char const* record, std::size_t index)
    {
        std::int32_t value = 0;
        std::memcpy(&value, record + index * 4, 4);
        return value;
    };

    auto const check = [&](Restore const* restores, std::size_t total, char const* missing, char const* broken)
    {
        bool present = true, stillBroken = true;
        for (std::size_t index = 0; index < total; ++index)
        {
            Restore const& restore = restores[index];
            auto const row = rows.find(restore.SpellId);
            if (row == rows.end() || restore.EffectIndex > 2)
            {
                present = false;
                std::printf("  missing spell %u effect %u\n", restore.SpellId, unsigned(restore.EffectIndex));
                continue;
            }
            std::int32_t const effect = field(row->second, SPELL_EFFECT + restore.EffectIndex);
            std::int32_t const aura = field(row->second, SPELL_AURA + restore.EffectIndex);
            std::int32_t const targetA = field(row->second, SPELL_TARGET_A + restore.EffectIndex);
            if (!Matches(restore.Broken, effect, aura, targetA))
            {
                stillBroken = false;
                std::printf("  spell %u effect %u is now effect %d aura %d target %d\n", restore.SpellId,
                    unsigned(restore.EffectIndex), effect, aura, targetA);
            }
        }
        Check(present, missing);
        Check(stillBroken, broken);
    };

    check(RESTORES, std::size(RESTORES), "every stock-script restore names a spell and slot in Spell.dbc",
        "every stock-script restore still finds the broken shape it is written for");
    check(DEAD_CATALOG_SLOTS, std::size(DEAD_CATALOG_SLOTS),
        "every dead catalog slot names a spell and slot in Spell.dbc",
        "every dead catalog slot is still dead in Spell.dbc");

    std::map<std::uint32_t, int> drainSoul;
    for (Restore const& restore : RESTORES)
        if (restore.Stock.Aura == AURA_CHANNEL_DEATH_ITEM)
            drainSoul[restore.SpellId] += restore.Stock.ItemType == SOUL_SHARD;
    Check(drainSoul.size() == 6, "all six Drain Soul ranks get their soul shard back");

    std::map<std::pair<std::uint32_t, std::uint8_t>, bool> percentHeals;
    for (auto const& [id, record] : rows)
        for (std::uint8_t index = 0; index < 3; ++index)
        {
            std::string const description = strings + field(record, SPELL_DESCRIPTION);
            std::string const promise = "$s" + std::to_string(index + 1) + "% of your max health";
            if (field(record, SPELL_EFFECT + index) == EFFECT_APPLY_AURA &&
                field(record, SPELL_AURA + index) == AURA_PERIODIC_HEAL && description.find(promise) != std::string::npos)
                percentHeals[{ id, index }] = false;
        }
    for (Restore const& restore : DEAD_CATALOG_SLOTS)
        if (restore.Stock.Aura == AURA_OBS_MOD_HEALTH)
            if (auto const itr = percentHeals.find({ restore.SpellId, restore.EffectIndex }); itr != percentHeals.end())
                itr->second = true;
    bool allRestored = !percentHeals.empty();
    for (auto const& [slot, restored] : percentHeals)
        if (!restored)
        {
            allRestored = false;
            std::printf("  spell %u effect %u heals a flat amount but its tooltip promises %% of max health\n",
                slot.first, unsigned(slot.second));
        }
    Check(allRestored, "every periodic heal whose tooltip promises % of max health heals that percentage");
    return failures ? 1 : 0;
}
"""


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-stock-script-shapes-") as directory:
        out = Path(directory)
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        executable = out / ("shapes.exe" if os.name == "nt" else "shapes")
        include = ROOT / "src/server/coa"
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/I" + str(include), str(out / "main.cpp"),
                     "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-I" + str(include), str(out / "main.cpp"), "-o",
                     str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Stock script shape harness did not compile:\n" + build.stdout + build.stderr)
        raise SystemExit(subprocess.run([str(executable), str(args.dbc_dir.resolve())], text=True).returncode)


if __name__ == "__main__":
    main()
