CLI_DESCRIPTION = """Check the free-pick Hero's Character Advancement rules without a server.

Compiles the free-pick rule code against the client DBC set the server loads (--dbc-dir), then checks the Hero
essence budget, class and realm admission, masteries, choice groups, investments, the unit rules, and how a
known-entries upload is accepted, reordered, refused and charged.
No database, server build or game client is needed.
"""

import argparse
import os
import re
import struct
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from coa_talent_catalog import STUBS  # noqa: E402
from client_data import dbc_dir  # noqa: E402

MAIN = r"""
#include "AscensionFreepickRules.h"
#include "DBCStores.h"
#include <cstdio>
#include <string>
#include <unordered_map>

using namespace AscensionFreepick;

namespace
{
int failures = 0;
void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

constexpr std::uint32_t PURIFY = 102;
constexpr std::uint32_t FERAL_SHAPESHIFT_MASTERY = 42016;
constexpr std::uint32_t BEAR_FORM = 42083;
constexpr std::uint32_t TAME_BEAST_ABILITIES = 40308;
constexpr std::uint32_t DOMINATE_UNDEAD = 41916;
constexpr std::uint32_t PATH_OF_STRENGTH = 1149;
constexpr std::uint32_t PATH_OF_AGILITY = 1150;
constexpr std::uint32_t BLOOD_GORGED_RANK_5 = 61158;
constexpr std::uint32_t WILL_OF_THE_NECROPOLIS_RANK_3 = 50150;
constexpr std::uint32_t PURIFY_SPELL = 1152;

bool Holds(std::vector<Entry> const& entries, std::uint32_t id, std::uint32_t rank)
{
    for (Entry const& entry : entries)
        if (entry.EntryId == id)
            return entry.Rank == rank;
    return false;
}

std::size_t PositionOf(std::vector<Entry> const& entries, std::uint32_t id)
{
    for (std::size_t index = 0; index < entries.size(); ++index)
        if (entries[index].EntryId == id)
            return index;
    return entries.size();
}
}

int main(int, char** argv)
{
    DbcDirectory = std::string(argv[1]) + "/";
    Catalog catalog;
    Check(LoadCatalog(catalog), "the advancement, class type and essence tables load");

    Realm realm;
    realm.Live = true;
    realm.Seasonal = true;

    Check(Build(catalog, realm, 12).AEBudget() == 32 && Build(catalog, realm, 12).TEBudget() == 3,
        "a level 12 Hero has the 32 AE and 3 TE seen on live Ascension");
    Check(Build(catalog, realm, 80).AEBudget() == 140 && Build(catalog, realm, 80).TEBudget() == 71,
        "a level 80 Hero has 140 AE and 71 TE");

    Row const* purify = catalog.Find(PURIFY);
    Row const* bear = catalog.Find(BEAR_FORM);
    Row const* tame = catalog.Find(TAME_BEAST_ABILITIES);
    Check(purify && bear && tame && catalog.Find(FERAL_SHAPESHIFT_MASTERY) && catalog.Find(DOMINATE_UNDEAD),
        "the entries the checks use are in the catalog");
    if (!purify || !bear || !tame)
        return 1;

    Check(ClassAdmits(catalog, *purify, HERO_CLASS) && ClassAdmits(catalog, *bear, HERO_CLASS),
        "the classic class trees admit a Hero");
    Check(!ClassAdmits(catalog, *purify, 2), "a Hero tree entry refuses a stock class");
    Check(Visible(catalog, realm, *purify), "Purify is offered on a live seasonal free-pick realm");
    Realm seasonal;
    seasonal.Seasonal = true;
    Check(purify->Realms[0] && !purify->Realms[1] && !Visible(catalog, seasonal, *purify),
        "an entry flagged for live realms only is hidden on a seasonal-only realm");
    std::size_t heroEntries = 0;
    for (auto const& [id, row] : catalog.Rows)
        heroEntries += ClassAdmits(catalog, row, HERO_CLASS) && Visible(catalog, realm, row);
    Check(heroEntries > 3000, "a live seasonal free-pick realm offers the Hero thousands of entries");

    Check(Build(catalog, realm, 12).ValidateLearn(PURIFY, nullptr) == LEARN_OK, "Purify is learnable at level 12");
    Check(Build(catalog, realm, 9).ValidateLearn(PURIFY, nullptr) == LEARN_LOW_LEVEL, "Purify is refused at level 9");
    Check(Build(catalog, realm, 12, { { PURIFY, purify->MaxRank() } }).ValidateLearn(PURIFY, nullptr) ==
        LEARN_ALREADY_KNOWN, "a rank past the entry's last is refused");

    Check(Build(catalog, realm, 12).ValidateLearn(BEAR_FORM, nullptr) == LEARN_MISSING_REQUIRED_ID,
        "Bear Form needs its mastery");
    Build druid(catalog, realm, 12, { { FERAL_SHAPESHIFT_MASTERY, 1 } });
    Check(druid.AutoLearn(nullptr) >= 1 && druid.RankOf(BEAR_FORM) == 1,
        "the mastery hands over Bear Form, which costs nothing");
    Check(druid.GlobalAE(0) == catalog.Find(FERAL_SHAPESHIFT_MASTERY)->AECost,
        "only the mastery is charged");

    Check(Build(catalog, realm, 20).ValidateLearn(TAME_BEAST_ABILITIES, nullptr) == LEARN_NOT_ENOUGH_INVESTED_AE,
        "a taming ability needs essence invested first");
    Check(Build(catalog, realm, 20, { { TAME_BEAST_ABILITIES, 1 } }).ValidateLearn(DOMINATE_UNDEAD, nullptr) ==
        LEARN_GROUP, "a second taming ability is refused: they share a choice group");

    UnitCheck const dead = [](std::uint32_t slot, Row const&) { return slot != LEARN_NOT_WHILE_DEAD; };
    Check(Build(catalog, realm, 12).ValidateLearn(PURIFY, dead) == LEARN_NOT_WHILE_DEAD, "the dead learn nothing");

    Build const base(catalog, realm, 12);
    ApplyCheck applied = CheckApply(base, { { PURIFY, 1 } }, nullptr, {});
    Check(applied.Result == UPDATE_OK && Holds(applied.Entries, PURIFY, 1), "an upload adding Purify applies");
    Check(CheckApply(base, {}, nullptr, {}).Result == UPDATE_NO_DIFF, "an upload that changes nothing is NO_DIFF");
    applied = CheckApply(base, { { 999999, 1 } }, nullptr, {});
    Check(applied.Result == UPDATE_BAD_ENTRY && applied.Failed.EntryId == 999999, "an unknown entry is BAD_ENTRY");
    Check(CheckApply(base, { { PURIFY, 1 }, { PURIFY, 1 } }, nullptr, {}).Result == UPDATE_BAD_ENTRY,
        "an entry listed twice is BAD_ENTRY");

    Check(CheckApply(base, { { PATH_OF_STRENGTH, 1 } }, nullptr, {}).Result == UPDATE_OK,
        "a level 1 Hero can choose a path");
    Check(CheckApply(base, { { PATH_OF_STRENGTH, 1 }, { PATH_OF_AGILITY, 1 } }, nullptr, {}).Result ==
        UPDATE_BAD_ENTRY, "two paths at once are BAD_ENTRY: a choice group holds one entry");
    Build const strength(catalog, realm, 20, { { PATH_OF_STRENGTH, 1 } });
    applied = CheckApply(strength, { { PATH_OF_AGILITY, 1 } }, nullptr, {});
    Check(applied.Result == UPDATE_OK && Holds(applied.Entries, PATH_OF_AGILITY, 1) && !applied.Money &&
        !applied.Marks, "switching path replaces the old one and costs nothing");

    applied = CheckApply(base, { { BEAR_FORM, 1 }, { FERAL_SHAPESHIFT_MASTERY, 1 } }, nullptr, {});
    Check(applied.Result == UPDATE_OK &&
            PositionOf(applied.Entries, FERAL_SHAPESHIFT_MASTERY) < PositionOf(applied.Entries, BEAR_FORM),
        "an upload naming Bear Form before its mastery is reordered, not refused");

    std::vector<Entry> greedy;
    std::uint32_t spent = 0;
    for (std::uint32_t id : catalog.RowOrder)
    {
        Row const& row = catalog.Rows.at(id);
        if (!row.AECost || row.TECost || Build(catalog, realm, 12).ValidateLearn(id, nullptr) != LEARN_OK)
            continue;
        greedy.push_back({ id, 1 });
        spent += row.AECost;
        if (spent > 32)
            break;
    }
    applied = CheckApply(base, greedy, nullptr, {});
    Check(spent > 32 && applied.Result == UPDATE_NOT_TRAVERSIBLE && applied.Learn == LEARN_MISSING_AE,
        "an upload over the essence budget is NOT_TRAVERSIBLE with MISSING_AE");

    Build const trained(catalog, realm, 20, { { PURIFY, 1 } });
    applied = CheckApply(trained, {}, nullptr, { 0, 250 });
    Check(applied.Result == UPDATE_OK && applied.Marks == 250 && applied.Money == 0,
        "unlearning at level 20 spends 250 Marks of Ascension while they last");
    applied = CheckApply(trained, {}, nullptr, { 71 * 20, 0 });
    Check(applied.Result == UPDATE_OK && applied.Money == 71 * 20 && applied.Marks == 0,
        "without marks the level 20 unlearn costs 71 copper per level");
    Check(CheckApply(trained, {}, nullptr, { 71 * 20 - 1, 0 }).Result == UPDATE_BAD_UPDATE_COSTS,
        "an unlearn nobody can pay for is BAD_UPDATE_COSTS");
    applied = CheckApply(Build(catalog, realm, 10, { { PURIFY, 1 } }), {}, nullptr, {});
    Check(applied.Result == UPDATE_OK && !applied.Money && !applied.Marks, "unlearning is free up to level 10");

    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> const learnEffects = { LEARN_EFFECTS };
    LearnedSpells const learned = [&learnEffects](std::uint32_t spellId)
    {
        auto const itr = learnEffects.find(spellId);
        return itr == learnEffects.end() ? std::vector<std::uint32_t>() : itr->second;
    };
    Check(TaughtSpells(BLOOD_GORGED_RANK_5, learned) == std::vector<std::uint32_t>({ 50111, 61278 }),
        "a rank that only teaches spells grants the spells it teaches");
    Check(TaughtSpells(WILL_OF_THE_NECROPOLIS_RANK_3, learned) == std::vector<std::uint32_t>({ 52286 }),
        "a rank with a learn effect beside other effects grants only the taught spell");
    Check(TaughtSpells(PURIFY_SPELL, learned) == std::vector<std::uint32_t>({ PURIFY_SPELL }),
        "a rank with no learn effect grants itself");

    return failures ? 1 : 0;
}
"""


PATH_SPELLS = (84864, 84865, 84866, 84867, 129243)
SPELL_DESCRIPTION = 170


def tooltip_spells(dbc):
    data = (dbc / "Spell.dbc").read_bytes()
    count, _, size, _ = struct.unpack_from("<4I", data, 4)
    strings = data[20 + count * size:]
    named = {}
    for row in range(count):
        spell_id = struct.unpack_from("<I", data, 20 + row * size)[0]
        if spell_id in PATH_SPELLS:
            offset = struct.unpack_from("<I", data, 20 + row * size + SPELL_DESCRIPTION * 4)[0]
            text = strings[offset:strings.index(bytes(1), offset)].decode("utf-8", "replace")
            named[spell_id] = sorted({int(value) for value in re.findall(r"@s:(\d+):", text)})
    return named


def companion_table():
    text = (ROOT / "src/server/coa/AscensionWildcard.cpp").read_text(encoding="utf-8")
    return {int(head): sorted(int(value) for value in spells.split(","))
            for head, spells in re.findall(r"\{ (\d+), \{ ([\d, ]+) \} \}", text)}


def check_path_passives(dbc):
    named, table = tooltip_spells(dbc), companion_table()
    ok = len(named) == len(PATH_SPELLS) and all(len(named[path]) == 2 and table.get(path) == named[path]
                                                 for path in PATH_SPELLS)
    print(f"{'PASS' if ok else 'FAIL'}: every path grants the two passives its tooltip names (@s:<spell>)")
    return ok


LEARN_SPELL_EFFECT = 36
SPELL_EFFECT, SPELL_TRIGGER = 71, 116


def learn_effects(directory):
    raw = (directory / "Spell.dbc").read_bytes()
    count, fields, size = struct.unpack_from("<III", raw, 4)
    rows = {row[0]: row for row in struct.iter_unpack(f"<{fields}I", raw[20:20 + count * size])}
    entries = []
    for spell in (61158, 50150, 1152):
        row = rows[spell]
        taught = [row[SPELL_TRIGGER + i] for i in range(3) if row[SPELL_EFFECT + i] == LEARN_SPELL_EFFECT]
        if taught:
            entries.append("{ %d, { %s } }" % (spell, ", ".join(map(str, taught))))
    source = (ROOT / "src/server/coa/AscensionFreepick.cpp").read_text(encoding="utf-8")
    assert source.count("RankSpells(row->Spells[") == 2, "free-pick grants and removals both expand rank spells"
    return ", ".join(entries)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-freepick-rules-") as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            (out / name).write_text(text, encoding="utf-8")
        (out / "main.cpp").write_text(MAIN.replace("LEARN_EFFECTS", learn_effects(args.dbc_dir.resolve())),
                                      encoding="utf-8")
        includes = [out, ROOT / "src/server/coa", ROOT / "src/server/shared/DataStores", ROOT / "src/common"]
        sources = [out / "main.cpp", ROOT / "src/server/coa/AscensionFreepickRules.cpp",
                   ROOT / "src/server/shared/DataStores/ClientDBC.cpp"]
        executable = out / ("rules.exe" if os.name == "nt" else "rules")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/utf-8", "/D_CRT_SECURE_NO_WARNINGS",
                     *["/I" + str(p) for p in includes], *map(str, sources), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", *["-I" + str(p) for p in includes], *map(str, sources),
                     "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Free-pick rules harness did not compile:\n" + build.stdout + build.stderr)
        result = subprocess.run([str(executable), str(args.dbc_dir.resolve())], text=True)
        paths_ok = check_path_passives(args.dbc_dir.resolve())
        raise SystemExit(result.returncode or (0 if paths_ok else 1))


if __name__ == "__main__":
    main()
