CLI_DESCRIPTION = """Check the Hero taming tables and Ascension's creature families against the client DBCs.

Compiles the taming tables against the client DBC set the server loads (--dbc-dir) and checks that every family
call spell re-summons the stored pet, that every taming channel takes only its family's creature type, and that
every creature family the world update assigns exists and teaches its pets a kit.
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from coa_talent_catalog import STUBS  # noqa: E402
from client_data import dbc_dir  # noqa: E402

FAMILY_UPDATE = ROOT / "data/sql/updates/pending_db_world/rev_20261003_20_ascension_creature_families.sql"

MAIN = r"""
#include "AscensionTamingData.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include <cstdio>
#include <cstdlib>
#include <map>
#include <set>

using namespace AscensionTaming;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

constexpr std::uint32_t SPELL_TARGET_CREATURE_TYPE = 17;
constexpr std::uint32_t SPELL_EFFECT = 71;
constexpr std::uint32_t SPELL_EFFECT_MISC_VALUE = 110;
constexpr std::uint32_t SPELL_EFFECT_SUMMON_PET = 56;
constexpr std::uint32_t FAMILY_SKILL_LINE = 5;
constexpr std::uint32_t ABILITY_SKILL_LINE = 1;
constexpr std::uint32_t ABILITY_ACQUIRE_METHOD = 9;
constexpr std::uint32_t LEARNED_ON_SKILL_LEARN = 2;
}

int main(int argc, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    ClientDBC spells, families, abilities;
    Check(spells.Load(GetClientDBCPath("Spell.dbc"), SPELL_EFFECT_MISC_VALUE + 3) &&
        families.Load(GetClientDBCPath("CreatureFamily.dbc"), FAMILY_SKILL_LINE + 2) &&
        abilities.Load(GetClientDBCPath("SkillLineAbility.dbc"), ABILITY_ACQUIRE_METHOD + 1),
        "Spell, CreatureFamily and SkillLineAbility load");

    std::map<std::uint32_t, std::uint32_t> spellRow;
    for (std::uint32_t row = 0; row < spells.GetRecordCount(); ++row)
        spellRow[spells.GetRecord(row).GetUInt32(0)] = row;

    bool callsSummonStored = true;
    for (FamilyCall const& call : FAMILY_CALLS)
    {
        auto const row = spellRow.find(call.SpellId);
        callsSummonStored = callsSummonStored && row != spellRow.end() &&
            spells.GetRecord(row->second).GetUInt32(SPELL_EFFECT) == SPELL_EFFECT_SUMMON_PET &&
            spells.GetRecord(row->second).GetUInt32(SPELL_EFFECT_MISC_VALUE) == 0;
    }
    Check(callsSummonStored, "every family call spell summons the stored pet (SUMMON_PET, creature 0)");

    bool channelsTyped = true;
    for (TamingChannel const& channel : TAMING_CHANNELS)
    {
        auto const row = spellRow.find(channel.SpellId);
        channelsTyped = channelsTyped && row != spellRow.end() &&
            spells.GetRecord(row->second).GetUInt32(SPELL_TARGET_CREATURE_TYPE) == CreatureTypeMask(channel.Kind);
    }
    Check(channelsTyped, "every taming channel targets only its family's creature type");

    std::set<std::uint32_t> taughtSkills;
    for (std::uint32_t row = 0; row < abilities.GetRecordCount(); ++row)
        if (abilities.GetRecord(row).GetUInt32(ABILITY_ACQUIRE_METHOD) == LEARNED_ON_SKILL_LEARN)
            taughtSkills.insert(abilities.GetRecord(row).GetUInt32(ABILITY_SKILL_LINE));
    std::map<std::uint32_t, std::pair<std::uint32_t, std::uint32_t>> familySkills;
    for (std::uint32_t row = 0; row < families.GetRecordCount(); ++row)
    {
        ClientDBC::Record const record = families.GetRecord(row);
        familySkills[record.GetUInt32(0)] = { record.GetUInt32(FAMILY_SKILL_LINE),
            record.GetUInt32(FAMILY_SKILL_LINE + 1) };
    }
    auto const teaches = [&](std::uint32_t family, bool ownKit)
    {
        auto const skills = familySkills.find(family);
        if (skills == familySkills.end())
            return false;
        return taughtSkills.count(skills->second.first) || (!ownKit && taughtSkills.count(skills->second.second));
    };

    bool assignedExist = argc > 2, assignedTeach = argc > 2;
    for (int index = 2; index < argc; ++index)
    {
        std::uint32_t const family = std::uint32_t(std::strtoul(argv[index], nullptr, 10));
        assignedExist = assignedExist && familySkills.count(family);
        assignedTeach = assignedTeach && teaches(family, false);
    }
    Check(assignedExist, "every family the world update assigns is in CreatureFamily.dbc");
    Check(assignedTeach, "every assigned family teaches its pets spells on one of its two skill lines");
    Check(teaches(105, true) && teaches(204, true) && teaches(301, true) && teaches(541, true),
        "the starter pets' families (Darkhound, Banshee, Air Elemental, Faerie Dragon) teach their own kit");

    return failures ? 1 : 0;
}
"""


def assigned_families():
    if not FAMILY_UPDATE.is_file():
        raise SystemExit(f"Missing {FAMILY_UPDATE}")
    text = FAMILY_UPDATE.read_text(encoding="utf-8")
    return sorted({int(value) for value in re.findall(r"SET `family` = (\d+)", text)})


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-taming-data-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores", ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("taming.exe" if os.name == "nt" else "taming")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", *["-I" + str(p) for p in includes], *map(str, sources),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Taming data harness did not compile:\n" + build.stdout + build.stderr)
        families = [str(family) for family in assigned_families()]
        result = subprocess.run([str(executable), str(args.dbc_dir.resolve()), *families], text=True)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
