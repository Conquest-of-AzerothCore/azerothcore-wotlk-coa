CLI_DESCRIPTION = """Check the Hero-learnable Ascension summons that had no creature, without a server.

Compiles AscensionSummonedEffects.h and checks every row against the Spell.dbc the server loads (--dbc-dir): the
summon spell summons the row's creature, the helper aura has the shape its behaviour reads (a periodic trigger with
no trigger spell for ticks, a dummy timer for expiries), and every payload exists. Then checks that the SQL creates
each creature with the engine's script and binds each helper to the script that reads it.
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

HEADER = ROOT / "src/server/coa/AscensionSummonedEffects.h"
SOURCE = ROOT / "src/server/coa/AscensionSummonedEffects.cpp"
LOADER = ROOT / "src/server/coa/CoAScriptLoader.cpp"
SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261004_20_coa_hero_summoned_effects.sql"

MAIN = r"""
#include "AscensionSummonedEffects.h"
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iterator>
#include <map>
#include <string>
#include <vector>

using namespace AscensionSummonedEffects;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

constexpr std::size_t EFFECT = 71;
constexpr std::size_t AURA = 95;
constexpr std::size_t MISC = 110;
constexpr std::size_t TRIGGER = 116;
constexpr std::int32_t SUMMON = 28;
constexpr std::int32_t APPLY_AURA = 6;
constexpr std::int32_t DUMMY = 4;
constexpr std::int32_t PERIODIC_TRIGGER_SPELL = 23;
}

int main(int, char** argv)
{
    std::ifstream file(std::string(argv[1]) + "/Spell.dbc", std::ios::binary);
    std::vector<char> data((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    Check(data.size() > 20 && std::memcmp(data.data(), "WDBC", 4) == 0, "Spell.dbc loads");
    if (failures)
        return 1;
    std::uint32_t count = 0, size = 0;
    std::memcpy(&count, data.data() + 4, 4);
    std::memcpy(&size, data.data() + 12, 4);
    std::map<std::uint32_t, char const*> rows;
    for (std::uint32_t row = 0; row < count; ++row)
    {
        char const* record = data.data() + 20 + std::size_t(row) * size;
        std::uint32_t id = 0;
        std::memcpy(&id, record, 4);
        rows[id] = record;
    }
    auto const field = [&](std::uint32_t spell, std::size_t index)
    {
        std::int32_t value = 0;
        std::memcpy(&value, rows.at(spell) + index * 4, 4);
        return value;
    };
    auto const known = [&](std::uint32_t spell) { return !spell || rows.count(spell); };

    bool summons = true, helpers = true, payloads = true, unique = true;
    std::map<std::pair<std::uint32_t, std::uint32_t>, int> seen;
    for (Summon const& row : SUMMONS)
    {
        unique = unique && ++seen[{ row.SummonSpell, row.Creature }] == 1;
        bool summoned = rows.count(row.SummonSpell);
        for (std::size_t index = 0; summoned && index < 3; ++index)
            if (field(row.SummonSpell, EFFECT + index) == SUMMON &&
                std::uint32_t(field(row.SummonSpell, MISC + index)) == row.Creature)
                break;
            else if (index == 2)
                summoned = false;
        if (!summoned)
            std::printf("  spell %u does not summon %u\n", row.SummonSpell, row.Creature);
        summons = summons && summoned;

        bool helper = !UsesHelper(row.Kind) || (row.Helper && rows.count(row.Helper) &&
            field(row.Helper, EFFECT) == APPLY_AURA);
        if (helper && (row.Kind == Behaviour::Tick || row.Kind == Behaviour::Freeze))
            helper = field(row.Helper, AURA) == PERIODIC_TRIGGER_SPELL && !field(row.Helper, TRIGGER);
        if (helper && row.Kind == Behaviour::Expire)
            helper = field(row.Helper, AURA) == DUMMY;
        if (helper && row.Kind == Behaviour::Aura)
            helper = field(row.Helper, AURA) == PERIODIC_TRIGGER_SPELL && field(row.Helper, TRIGGER);
        if (!helper)
            std::printf("  spell %u helper %u has the wrong shape\n", row.SummonSpell, row.Helper);
        helpers = helpers && helper;

        bool payload = known(row.Payload) && known(row.Extra) &&
            (row.Payload || row.Kind == Behaviour::Anchor || row.Kind == Behaviour::Aura ||
            row.Kind == Behaviour::Attack || row.Kind == Behaviour::Return);
        if (row.Kind == Behaviour::Return || row.Kind == Behaviour::Vortex || row.Kind == Behaviour::Store)
            payload = payload && row.Helper && rows.count(row.Helper);
        if (!payload)
            std::printf("  spell %u payload %u / %u missing\n", row.SummonSpell, row.Payload, row.Extra);
        payloads = payloads && payload;
    }
    Check(unique, "every summon spell and creature pair has one row");
    Check(summons, "every row's summon spell summons the row's creature");
    Check(helpers, "every helper aura has the shape its behaviour reads");
    Check(payloads, "every payload exists in Spell.dbc");
    for (Summon const& row : SUMMONS)
        std::printf("ROW %u %u %u %u %u %u\n", row.Creature, unsigned(row.Kind), row.Helper, row.SummonSpell,
            row.Payload, row.Extra);
    return failures ? 1 : 0;
}
"""

HELPER_SCRIPT = {4: "aura_ascension_summoned_effect_tick", 8: "aura_ascension_summoned_effect_tick",
                 5: "aura_ascension_summoned_effect_expire", 10: "aura_ascension_cloudburst",
                 14: "aura_ascension_ursols_vortex_range", 15: "aura_ascension_alter_time"}
PAYLOAD_SCRIPT = {10: "spell_ascension_cloudburst_heal", 2: "spell_ascension_skull_banner"}


EFFECT, TARGET_A, TARGET_B, MISC, MISC_B = 71, 86, 89, 110, 113
SUMMON, ALLY_AREA = 28, 31


def load_rows(path):
    raw = path.read_bytes()
    count, fields, size = struct.unpack_from("<III", raw, 4)
    return {row[0]: row for row in struct.iter_unpack(f"<{fields}i", raw[20:20 + count * size])}


def check(value, name):
    print(("PASS" if value else "FAIL") + ": " + name)
    return bool(value)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()
    if not HEADER.exists():
        raise SystemExit("FAIL: " + str(HEADER.relative_to(ROOT)) + " is missing")

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-summoned-effects-") as directory:
        out = Path(directory)
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        executable = out / ("effects.exe" if os.name == "nt" else "effects")
        include = ROOT / "src/server/coa"
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/I" + str(include), str(out / "main.cpp"),
                     "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-I" + str(include), str(out / "main.cpp"), "-o",
                     str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Summoned effects harness did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), str(args.dbc_dir.resolve())], capture_output=True, text=True)

    table = []
    for line in result.stdout.splitlines():
        if line.startswith("ROW "):
            table.append(tuple(int(x) for x in line.split()[1:]))
        else:
            print(line)
    ok = result.returncode == 0

    sql = SQL.read_text(encoding="utf-8") if SQL.exists() else ""
    created = {int(m[1]): m[2] for m in
               re.finditer(r"^\((\d+), '.*?', .*?'(\w*)'\)(?:,| ON DUPLICATE KEY UPDATE .*;)$", sql, re.M)}
    engine = {row[0] for row in table}
    ok &= check(engine and all(created.get(c) == "npc_ascension_summoned_effect" for c in engine),
                "the SQL creates every engine creature with npc_ascension_summoned_effect")
    bound = {(int(m[1]), m[2]) for m in re.finditer(r"\((\d+), '(\w+)'\)", sql)}
    wanted = {(row[2], HELPER_SCRIPT[row[1]]) for row in table if row[1] in HELPER_SCRIPT}
    wanted |= {(row[4], PAYLOAD_SCRIPT[row[1]]) for row in table
               if row[1] in PAYLOAD_SCRIPT and (row[1] != 2 or row[5])}
    ok &= check(wanted and wanted <= bound, "the SQL binds every helper to the script that reads it")

    spells = load_rows(args.dbc_dir.resolve() / "Spell.dbc")
    properties = load_rows(args.dbc_dir.resolve() / "SummonProperties.dbc")
    plain = set()
    for creature, _, _, summon, _, _ in table:
        for index in range(3):
            row = spells.get(summon)
            prop = properties.get(row[MISC_B + index]) if row else None
            if row and row[EFFECT + index] == SUMMON and row[MISC + index] == creature and prop and \
                    prop[1] in (0, 1, 5) and not prop[5] & 512 and prop[3] in (0, 7, 8):
                plain.add((summon, "spell_ascension_summoned_effect_summon"))
    ok &= check(plain and plain <= bound,
                "every summon the core would create without its spell id is summoned by the engine's spell script")
    ally = {(spell, "spell_ascension_summoned_effect_ally_area") for row in table if row[1] != 10
            for spell in row[4:6] if spell in spells and
            any(ALLY_AREA in (spells[spell][TARGET_A + i], spells[spell][TARGET_B + i]) for i in range(3))}
    ok &= check(ally and ally <= bound, "every ally-area payload skips the summons themselves")
    source = SOURCE.read_text(encoding="utf-8") if SOURCE.exists() else ""
    registered = set(re.findall(r"Register(?:SpellScript|CreatureAI)\((\w+)\)", source))
    ok &= check({name for _, name in bound} <= registered and "npc_ascension_summoned_effect" in registered,
                "every bound script is registered")
    ok &= check("AddSC_AscensionSummonedEffects();" in LOADER.read_text(encoding="utf-8"),
                "the script loader adds the summoned effects")
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
