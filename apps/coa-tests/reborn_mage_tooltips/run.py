CLI_DESCRIPTION = """Check that Warcraft Reborn Mage spells are wired to do what their own tooltips say."""

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
AURA, MISC, MASK, FAMILY_FLAGS = 95, 110, 122, 209
BASE = 80
SPELL_AURA_ADD_FLAT_MODIFIER, SPELL_AURA_ADD_PCT_MODIFIER = 107, 108
SPELLMOD_DAMAGE, SPELLMOD_CRITICAL_CHANCE, SPELLMOD_DOT = 0, 7, 22
WORLD_IN_FLAMES = (1111108, 1112349, 1112350)
FIRE_POWER = (1111124, 1112378, 1112398)
LIVING_BOMB = (1144457, 1155359, 1155360)


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
    bombs = [spells[spell][FAMILY_FLAGS:FAMILY_FLAGS + 3] for spell in LIVING_BOMB if spell in spells]
    if len(bombs) != len(LIVING_BOMB) or any(not flags[1] & 0x20000 for flags in bombs):
        problems.append("a Reborn Living Bomb rank no longer carries family flag [1] 0x20000")
    for spell in WORLD_IN_FLAMES:
        row = spells.get(spell)
        if not row or row[AURA] != SPELL_AURA_ADD_FLAT_MODIFIER or row[MISC] != SPELLMOD_CRITICAL_CHANCE:
            problems.append(f"World in Flames {spell} effect 1 is no longer its crit modifier")
        elif row[MASK + 1] & 0x20000:
            problems.append(f"World in Flames {spell} already covers Living Bomb")
    for spell in FIRE_POWER:
        row = spells.get(spell)
        if not row or row[AURA:AURA + 2] != (SPELL_AURA_ADD_PCT_MODIFIER, SPELL_AURA_ADD_PCT_MODIFIER) or                 row[MISC:MISC + 2] != (SPELLMOD_DAMAGE, SPELLMOD_DOT):
            problems.append(f"Fire Power {spell} no longer has its damage and periodic damage modifiers")
        elif row[BASE] == row[BASE + 1]:
            problems.append(f"Fire Power {spell} periodic bonus already matches its damage bonus")
    return check(not problems, "the client rows match what the fixes assume (Living Bomb flag, World in Flames mask "
                 "without it, Fire Power's smaller periodic bonus)", problems)


CONTRACTS = r"""
#include <cassert>
#include <cstdint>
#include <array>
#include <algorithm>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_ADD_FLAT_MODIFIER = 107, SPELL_AURA_ADD_PCT_MODIFIER = 108 };
enum SpellModOp { SPELLMOD_DAMAGE = 0, SPELLMOD_CRITICAL_CHANCE = 7, SPELLMOD_DOT = 22 };
enum SpellEffIndex { EFFECT_0 = 0, EFFECT_1 = 1 };
struct flag96
{
    uint32 part[3] = {};
    uint32& operator[](int index) { return part[index]; }
};
struct SpellEffectInfo { AuraType ApplyAuraName = SPELL_AURA_NONE; int32 MiscValue = 0; int32 BasePoints = 0; flag96 SpellClassMask; };
struct SpellInfo { uint32 Id = 0; SpellEffectInfo Effects[3]; };
namespace AscensionWarcraftReborn
{
"""


def check_contracts():
    source_ = source("src/server/coa/AscensionWarcraftRebornMage.cpp")
    apply = body(source_, "void ApplyAscensionWarcraftRebornMageContracts(SpellInfo* spellInfo)")
    mechanics = source("src/server/coa/AscensionClassMechanics.cpp")
    if not apply or "ApplyAscensionWarcraftRebornMageContracts(spellInfo);" not in mechanics:
        return check(False, "World in Flames covers Living Bomb; Fire Power's periodic bonus matches its damage bonus",
                     ["the Mage contracts are not applied"])
    constants = "\n".join(re.findall(r"^constexpr (?:uint32|std::array<uint32, \d+>) .*;", source_, re.M))
    code = CONTRACTS + constants + "\n}\n" + apply + r"""
int main()
{
    for (uint32 id : { 1111108u, 1112349u, 1112350u })
    {
        SpellInfo talent; talent.Id = id;
        talent.Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
        talent.Effects[0].MiscValue = SPELLMOD_CRITICAL_CHANCE;
        talent.Effects[0].SpellClassMask[0] = 0xc01084; talent.Effects[0].SpellClassMask[1] = 0x10040;
        ApplyAscensionWarcraftRebornMageContracts(&talent);
        assert(talent.Effects[0].SpellClassMask[1] == (0x10040u | 0x20000u));
        assert(talent.Effects[0].SpellClassMask[0] == 0xc01084 && talent.Effects[0].SpellClassMask[2] == 0);
    }
    for (auto [id, damage, periodic] : { std::array<int32, 3>{ 1111124, 3, 1 }, std::array<int32, 3>{ 1112378, 6, 3 },
                                          std::array<int32, 3>{ 1112398, 9, 5 } })
    {
        SpellInfo talent; talent.Id = uint32(id);
        talent.Effects[0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER; talent.Effects[0].MiscValue = SPELLMOD_DAMAGE;
        talent.Effects[0].BasePoints = damage;
        talent.Effects[1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER; talent.Effects[1].MiscValue = SPELLMOD_DOT;
        talent.Effects[1].BasePoints = periodic;
        ApplyAscensionWarcraftRebornMageContracts(&talent);
        assert(talent.Effects[1].BasePoints == damage && talent.Effects[0].BasePoints == damage);
        assert(talent.Effects[0].SpellClassMask[1] == 0);
    }
    SpellInfo other; other.Id = 12350;
    other.Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
    other.Effects[0].MiscValue = SPELLMOD_CRITICAL_CHANCE;
    ApplyAscensionWarcraftRebornMageContracts(&other);
    assert(other.Effects[0].SpellClassMask[1] == 0);
}
"""
    return check(compile_and_run(code, "coa-reborn-mage-contracts-"),
                 "World in Flames' crit bonus covers Living Bomb; Fire Power's periodic bonus is its 4/7/10%")


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
    results = [check_client(directory), check_contracts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
