CLI_DESCRIPTION = """Check the wardrobe cosmetic pet rules against the client DBCs.

Compiles AscensionTamingData.h against the client DBC set the server loads (--dbc-dir) and checks that the
summon and dismiss spells each class needs (Extensions.dll FUN_100c1b40) match AppearanceCategories and Spell.dbc,
that each pet tier is the creature kind its category names, and that pet tokens drop only on the realm types whose
classes can use them. It also checks the world update builds only tameable pet creatures with a family.
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

CREATURES = ROOT / "data/sql/updates/pending_db_world/rev_20261103_70_coa_cosmetic_pet_creatures.sql"

MAIN = r"""
#include "AscensionTamingData.h"
#include "ClientDBC.h"
#include "DBCStores.h"
#include <cstdio>
#include <map>
#include <set>
#include <string>

using namespace AscensionTaming;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

constexpr std::uint32_t SPELL_EFFECT = 71;
constexpr std::uint32_t SPELL_EFFECT_MISC_VALUE = 110;
constexpr std::uint32_t SPELL_EFFECT_SUMMON_PET = 56;
constexpr std::uint32_t SPELL_EFFECT_DISMISS_PET = 102;
constexpr std::uint32_t CATEGORY_TIER = 19;
constexpr std::uint32_t CATEGORY_SUMMON = 20;
constexpr std::uint32_t CATEGORY_DISMISS = 21;
constexpr std::uint32_t CATEGORY_CLASS_MASK = 23;
}

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    ClientDBC spells, categories;
    Check(spells.Load(GetClientDBCPath("Spell.dbc"), SPELL_EFFECT_MISC_VALUE + 3) &&
        categories.Load(GetClientDBCPath("AppearanceCategories.dbc"), CATEGORY_CLASS_MASK + 2),
        "Spell and AppearanceCategories load");

    std::map<std::uint32_t, std::uint32_t> spellRow;
    for (std::uint32_t row = 0; row < spells.GetRecordCount(); ++row)
        spellRow[spells.GetRecord(row).GetUInt32(0)] = row;
    auto const hasEffect = [&](std::uint32_t spell, std::uint32_t effect, bool firstOnly)
    {
        auto const row = spellRow.find(spell);
        if (row == spellRow.end())
            return false;
        ClientDBC::Record const record = spells.GetRecord(row->second);
        for (std::uint32_t index = 0; index < (firstOnly ? 1u : 3u); ++index)
            if (record.GetUInt32(SPELL_EFFECT + index) == effect &&
                (effect != SPELL_EFFECT_SUMMON_PET || record.GetUInt32(SPELL_EFFECT_MISC_VALUE + index) == 0))
                return true;
        return false;
    };

    std::map<std::string, std::uint32_t> const kinds = { { "Tamed Beast", KIND_BEAST },
        { "Summoned Demon", KIND_DEMON }, { "Raised Undead", KIND_UNDEAD }, { "Tamed Dragonkin", KIND_DRAGONKIN },
        { "Tamed Elemental", KIND_ELEMENTAL } };
    std::map<std::string, std::uint64_t> masks;
    bool heroSpellsMatch = true, kindsMatch = true;
    for (std::uint32_t row = 0; row < categories.GetRecordCount(); ++row)
    {
        ClientDBC::Record const record = categories.GetRecord(row);
        if (record.GetString(1) != "APPEARANCE_TYPE_COSMETIC_PET")
            continue;
        std::string const name(record.GetString(2));
        std::uint32_t const tier = record.GetUInt32(CATEGORY_TIER);
        PetSpells const hero = CosmeticPetSpells(CLASS_HERO_ID, tier);
        heroSpellsMatch = heroSpellsMatch && hero.Summon == record.GetUInt32(CATEGORY_SUMMON) &&
            hero.Dismiss == record.GetUInt32(CATEGORY_DISMISS);
        auto const kind = kinds.find(name);
        kindsMatch = kindsMatch && kind != kinds.end() && CosmeticPetKind(tier) == kind->second;
        masks[name] = record.GetUInt32(CATEGORY_CLASS_MASK) |
            (std::uint64_t(record.GetUInt32(CATEGORY_CLASS_MASK + 1)) << 32);
    }
    Check(masks.size() == COSMETIC_PET_TIER_COUNT, "the client has five cosmetic pet categories");
    Check(heroSpellsMatch, "a Hero needs each category's own summon and dismiss spell (AppearanceCategories 20/21)");
    Check(kindsMatch, "each category's tier is the creature kind it names");

    bool summons = true, dismisses = true;
    for (std::uint32_t classId : { 3u, 9u, 10u, 31u })
        for (std::uint32_t tier = 1; tier <= COSMETIC_PET_TIER_COUNT; ++tier)
        {
            PetSpells const pet = CosmeticPetSpells(classId, tier);
            summons = summons && hasEffect(pet.Summon, SPELL_EFFECT_SUMMON_PET, true);
            dismisses = dismisses && hasEffect(pet.Dismiss, SPELL_EFFECT_DISMISS_PET, false);
        }
    Check(summons, "every class's summon spell calls the stored pet (SUMMON_PET, creature 0)");
    Check(dismisses, "every class's dismiss spell dismisses the pet");
    Check(CosmeticPetSpells(3, 1).Summon == 1100883 && CosmeticPetSpells(31, 1).Summon == 574302 &&
        CosmeticPetSpells(31, 2).Summon == 884 && CosmeticPetSpells(9, 3).Summon == 885,
        "stock, CoA and Hero classes take the client's own spell branches");

    auto const dropsOn = [&](std::string const& category, bool coa, bool wcr)
    {
        return (masks[category] & RealmClassMask(coa, wcr)) != 0;
    };
    Check(dropsOn("Tamed Beast", true, false) && !dropsOn("Summoned Demon", true, false) &&
        !dropsOn("Raised Undead", true, false) && !dropsOn("Tamed Dragonkin", true, false) &&
        !dropsOn("Tamed Elemental", true, false), "a Conquest of Azeroth realm drops only Tamed Beast tokens");
    Check(dropsOn("Tamed Beast", false, true) && dropsOn("Summoned Demon", false, true) &&
        !dropsOn("Raised Undead", false, true) && dropsOn("Tamed Dragonkin", false, true) &&
        dropsOn("Tamed Elemental", false, true), "a Warcraft Reborn realm drops every token but Raised Undead");
    bool hero = true;
    for (auto const& [category, mask] : masks)
        hero = hero && dropsOn(category, false, false);
    Check(hero, "a Hero (Freepick, Wildcard) realm drops every token");

    return failures ? 1 : 0;
}
"""

TEMPLATE_ROW = re.compile(
    r"^\((\d+), 0, 0, 0, .*, 0, 2048, 0, (\d+), (\d+), (\d+), 0, 0, 0, \d+, 0, 0, 0, '', 0, .*, '', (\d+)\)[,;]?$", re.M)


def check_world_update():
    if not CREATURES.is_file():
        raise SystemExit(f"Missing {CREATURES}")
    text = CREATURES.read_text(encoding="utf-8")
    rows = [tuple(map(int, match.groups())) for match in TEMPLATE_ROW.finditer(text)]
    inserted = len(re.findall(r"^\(\d+, 0, 0, 0, ", text, re.M))
    built = [row for row in rows if row[4] == 0]
    tameable = built and all(flags & 1 for _, _, _, flags, _ in built)
    families = all(family for _, family, _, _, _ in rows)
    results = [(rows and len(rows) == inserted, f"every inserted pet template parses ({len(rows)})"),
               (tameable, f"every pet creature built from client data is tameable, so it can be stored ({len(built)})"),
               (families, "every inserted pet creature has a family")]
    for value, name in results:
        print(f"{'PASS' if value else 'FAIL'}: {name}")
    return all(value for value, _ in results)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-cosmetic-pets-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores", ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("pets.exe" if os.name == "nt" else "pets")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", *["-I" + str(p) for p in includes], *map(str, sources),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Cosmetic pet harness did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), str(args.dbc_dir.resolve())], text=True)
        world = check_world_update()
        raise SystemExit(0 if result.returncode == 0 and world else 1)


if __name__ == "__main__":
    main()
