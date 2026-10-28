CLI_DESCRIPTION = """Check that Warcraft Reborn Druid spells are wired to do what their own tooltips say."""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
EFFECT, AURA, MISC, MASK, BASE, TRIGGER = 71, 95, 110, 122, 80, 116
SPELL_AURA_PERIODIC_TRIGGER_SPELL, SPELL_AURA_OVERRIDE_CLASS_SCRIPTS = 23, 112
TRANQUILITY = (1100740, 1108918, 1109862, 1109863, 1126983, 1148446, 1148447)
REVITALIZE = (1148539, 1148544, 1148545)
MIGRATION = "data/sql/updates/pending_db_world/rev_20261016_40_reborn_druid_tooltips.sql"


def read_dbc(path):
    data = path.read_bytes()
    count, fields, size, _ = struct.unpack_from("<4I", data, 4)
    rows = {}
    for row in range(count):
        record = struct.unpack_from("<%dI" % fields, data, 20 + row * size)
        rows[record[0]] = record
    return rows


def source(name):
    path = ROOT / name
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def body(text_, signature):
    return method(text_, signature) if signature in text_ else ""


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def check_client(directory):
    spells = read_dbc(directory / "Spell.dbc")
    problems = []
    druid = source("src/server/coa/AscensionWarcraftRebornDruid.cpp")
    pairs = re.findall(r"\{ (\d+), (\d+) \}", druid)
    if len(pairs) != len(TRANQUILITY) or [int(p) for p, _ in pairs] != list(TRANQUILITY):
        problems.append("the Tranquility parent/tick table does not list the seven Reborn ranks")
    for parent, tick in ((int(p), int(t)) for p, t in pairs):
        row = spells.get(parent)
        if not row or row[AURA + 1] != SPELL_AURA_PERIODIC_TRIGGER_SPELL or row[TRIGGER + 1] != tick:
            problems.append(f"Tranquility {parent} no longer triggers {tick}")
        elif spells.get(tick, (0,) * 200)[BASE] == row[BASE]:
            problems.append(f"Tranquility tick {tick} already carries its parent's value")
    for spell in REVITALIZE:
        row = spells.get(spell)
        if not row or row[AURA] != SPELL_AURA_OVERRIDE_CLASS_SCRIPTS:
            problems.append(f"Revitalize {spell} effect 1 is no longer the class-script aura spell_dru_revitalize reads")
    return check(not problems, "the client rows match what the fixes assume (Tranquility parents and ticks, Revitalize "
                 "class-script effect)", problems)


def check_wiring():
    problems = []
    migration = source(MIGRATION)
    for row in ("`SpellFamilyMask2` | 0x80000", "WHERE `SpellId` = -48506", "(-1137116, 0, 0, 0, 0, 0, 0x14, 1, 2, 2,",
                "(-1148539, 0, 7, 0x10, 0x4000000, 0, 0x40000, 2, 2, 0,",
                "(1121178, -57339, 2,",
                "(-1137116, 'spell_ascension_reborn_primal_fury')", "(-1148539, 'spell_dru_revitalize')"):
        if row not in migration:
            problems.append(f"{MIGRATION} lacks {row}")
    druid = source("src/server/coa/AscensionWarcraftRebornDruid.cpp")
    if "RegisterSpellScript(spell_ascension_reborn_primal_fury);" not in druid:
        problems.append("the Primal Fury script is not registered")
    return check(not problems, "Earth and Moon procs from Starsurge, Primal Fury and Revitalize proc, Bear Form skips the stock "
                 "tank passive", problems)


CONTRACTS = r"""
#include <cassert>
#include <cstdint>
#include <cstddef>
#include <array>
#include <algorithm>
#include <utility>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
enum SpellEffects { SPELL_EFFECT_APPLY_AURA = 6, SPELL_EFFECT_HEAL = 10 };
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_ADD_PCT_MODIFIER = 108 };
enum SpellCustomAttributes : uint32 { SPELL_ATTR0_CU_IGNORE_ARMOR = 0x00008000 };
enum SpellModOp { SPELLMOD_DAMAGE = 0, SPELLMOD_THREAT = 2, SPELLMOD_COST = 14, SPELLMOD_DOT = 22 };
enum SpellEffIndex { EFFECT_0 = 0, EFFECT_1 = 1, EFFECT_2 = 2 };
struct flag96
{
    uint32 part[3] = {};
    uint32& operator[](int index) { return part[index]; }
};
struct SpellEffectInfo { uint32 Effect = 0; AuraType ApplyAuraName = SPELL_AURA_NONE; int32 MiscValue = 0;
    int32 BasePoints = 0; float RealPointsPerLevel = 0; uint8 EffectIndex = 0; flag96 SpellClassMask; };
struct SpellInfo { uint32 Id = 0; uint32 AttributesCu = 0; SpellEffectInfo Effects[3]; };
struct Manager
{
    SpellInfo parent;
    SpellInfo const* GetSpellInfo(uint32 id) const { return id == parent.Id ? &parent : nullptr; }
} manager;
Manager* sSpellMgr = &manager;
namespace AscensionWarcraftReborn
{
"""


def check_contracts():
    source_ = source("src/server/coa/AscensionWarcraftRebornDruid.cpp")
    apply = body(source_, "void ApplyAscensionWarcraftRebornDruidContracts(SpellInfo* spellInfo)")
    mechanics = source("src/server/coa/AscensionClassMechanics.cpp")
    if not apply or "ApplyAscensionWarcraftRebornDruidContracts(spellInfo);" not in mechanics:
        return check(False, "the Druid contracts follow the tooltips", ["the Druid contracts are not applied"])
    constants = "\n".join(re.findall(r"^constexpr (?:uint32|std::array<[^;]+?>) .*?;", source_, re.M | re.S))
    contains = body(source_, "bool Contains(std::array<uint32, N> const& ids, uint32 id)")
    code = CONTRACTS + constants + "\ntemplate <std::size_t N>\n" + contains + "\n}\n" + apply + r"""
SpellInfo Modifier(uint32 id, int32 misc0, int32 misc1 = 0)
{
    SpellInfo info; info.Id = id;
    info.Effects[0].MiscValue = misc0; info.Effects[1].MiscValue = misc1;
    return info;
}

int main()
{
    manager.parent.Id = 1148447;
    manager.parent.Effects[0].BasePoints = 3034; manager.parent.Effects[0].RealPointsPerLevel = 9.0f;
    SpellInfo tick; tick.Id = 1148445;
    tick.Effects[0].Effect = SPELL_EFFECT_HEAL; tick.Effects[0].BasePoints = 2184; tick.Effects[0].RealPointsPerLevel = 4.05f;
    ApplyAscensionWarcraftRebornDruidContracts(&tick);
    assert(tick.Effects[0].BasePoints == 3034 && tick.Effects[0].RealPointsPerLevel == 9.0f);

    SpellInfo gift = Modifier(1124946, SPELLMOD_DAMAGE, SPELLMOD_DOT);
    ApplyAscensionWarcraftRebornDruidContracts(&gift);
    assert(gift.Effects[0].SpellClassMask[1] == 0x2);

    SpellInfo shifter = Modifier(1116835, SPELLMOD_COST);
    shifter.Effects[0].SpellClassMask[0] = 0xc0000000;
    ApplyAscensionWarcraftRebornDruidContracts(&shifter);
    assert(shifter.Effects[0].SpellClassMask[0] == 0xe0000000);

    SpellInfo brambles = Modifier(1116840, SPELLMOD_DAMAGE, SPELLMOD_DOT);
    brambles.Effects[0].BasePoints = 99; brambles.Effects[1].BasePoints = 74;
    ApplyAscensionWarcraftRebornDruidContracts(&brambles);
    assert(brambles.Effects[1].BasePoints == 99);

    SpellInfo moonfury = Modifier(1116896, SPELLMOD_DAMAGE, SPELLMOD_DOT);
    ApplyAscensionWarcraftRebornDruidContracts(&moonfury);
    assert(moonfury.Effects[0].SpellClassMask[2] == 0x80000);

    SpellInfo reach = Modifier(1116820, 5, SPELLMOD_THREAT);
    reach.Effects[1].SpellClassMask[2] = 0x400000;
    ApplyAscensionWarcraftRebornDruidContracts(&reach);
    assert(reach.Effects[1].SpellClassMask[2] == 0x480000);

    SpellInfo rake; rake.Id = 1148574;
    ApplyAscensionWarcraftRebornDruidContracts(&rake);
    assert(rake.AttributesCu & SPELL_ATTR0_CU_IGNORE_ARMOR);

    SpellInfo instinct; instinct.Id = 1116949;
    instinct.Effects[1].Effect = SPELL_EFFECT_APPLY_AURA; instinct.Effects[1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    instinct.Effects[1].MiscValue = SPELLMOD_DAMAGE; instinct.Effects[1].BasePoints = 29; instinct.Effects[1].EffectIndex = 1;
    instinct.Effects[1].SpellClassMask[1] = 0x100000; instinct.Effects[1].SpellClassMask[2] = 0x400;
    ApplyAscensionWarcraftRebornDruidContracts(&instinct);
    assert(instinct.Effects[2].Effect == SPELL_EFFECT_APPLY_AURA && instinct.Effects[2].MiscValue == SPELLMOD_DOT);
    assert(instinct.Effects[2].BasePoints == 29 && instinct.Effects[2].EffectIndex == 2);
    assert(instinct.Effects[2].SpellClassMask[1] == 0x100000 && instinct.Effects[1].MiscValue == SPELLMOD_DAMAGE);

    SpellInfo stock = Modifier(24946, SPELLMOD_DAMAGE);
    ApplyAscensionWarcraftRebornDruidContracts(&stock);
    assert(stock.Effects[0].SpellClassMask[1] == 0);
}
"""
    return check(compile_and_run(code, "coa-reborn-druid-contracts-"),
                 "Tranquility ticks for its tooltip value, and Gift of Nature, Natural Shapeshifter, Brambles, Moonfury "
                 "and Nature's Reach cover what their tooltips name; Rake's opening bleed ignores armor; Feral Instinct "
                 "raises Thrash's bleed")


def compile_and_run(code, prefix):
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix=prefix) as directory:
        out = Path(directory)
        cpp, exe = out / "contracts.cpp", out / ("contracts.exe" if os.name == "nt" else "contracts")
        cpp.write_text(code, encoding="utf-8")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", str(cpp), "/Fe" + str(exe)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        return subprocess.run([str(exe)], cwd=out).returncode == 0


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = (args.dbc_dir or dbc_dir()).resolve()
    results = [check_client(directory), check_wiring(), check_contracts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
