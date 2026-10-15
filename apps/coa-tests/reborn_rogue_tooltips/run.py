CLI_DESCRIPTION = """Check that Warcraft Reborn Rogue spells are wired to do what their own tooltips say."""

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
PENDING = ROOT / "data/sql/updates/pending_db_world"
EFFECT, BASE_POINTS, AURA, DESCRIPTION, FAMILY, FAMILY_FLAGS = 71, 80, 95, 170, 208, 209
TRIGGER_SPELL = 116
SPELL_AURA_DUMMY = 4
CRIMSON_TEMPEST = range(2304883, 2304890)
POISON_NOVA = (983281, 983283, 983284, 983285, 983286, 983287, 983288, 983289, 983290, 983291)
SABER_SLASH, SAVAGE_COMBAT = 1587522, (1151682, 1158413)
AMBUSH_FLAG, RELENTLESS_STRIKES_ENERGY, ANESTHETIC_POISON = 0x200, 1114181, 1126688
REBORN_SPELL_OFFSET = 1100000
RELENTLESS_STRIKES = (1114179, 1158422, 1158423, 1158424, 1158425)


def read_dbc(path):
    data = path.read_bytes()
    count, fields, size, _ = struct.unpack_from("<4I", data, 4)
    rows = {}
    for row in range(count):
        record = struct.unpack_from("<%dI" % fields, data, 20 + row * size)
        rows[record[0]] = record
    return rows, data, 20 + count * size


def text(data, base, offset):
    return data[base + offset:data.index(b"\0", base + offset)].decode("utf-8", "replace")


def source(name):
    path = ROOT / name
    return path.read_text(encoding="utf-8") if path.is_file() else ""


def body(text_, signature):
    return method(text_, signature) if signature in text_ else ""


def sql_rows(table):
    rows = []
    for path in sorted(PENDING.glob("rev_*.sql")):
        sql = path.read_text(encoding="utf-8")
        if not sql.startswith("-- Warcraft Reborn Rogue:"):
            continue
        for block in re.findall(r"INSERT INTO `" + table + r"`[^;]*;", sql):
            values = block.split("VALUES", 1)[1]
            rows += [row.split(", ") for row in re.findall(r"\(([^()]*)\)", values)]
    return rows


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def check_tooltips(spells, data, base):
    ambush = [spell_id for spell_id, record in spells.items() if spell_id >= REBORN_SPELL_OFFSET and
              spell_id - REBORN_SPELL_OFFSET in spells and record[FAMILY] == 8 and record[FAMILY_FLAGS] & AMBUSH_FLAG and
              record[EFFECT] == 121 and record[EFFECT + 1] == 31]
    problems = [f"Ambush {spell} tooltip does not multiply its flat bonus by 2.75" for spell in ambush
                if "${$m1*2.75}" not in text(data, base, spells[spell][DESCRIPTION])]
    relentless = [spell_id for spell_id, record in spells.items() if record[TRIGGER_SPELL] == RELENTLESS_STRIKES_ENERGY and
                  record[EFFECT] == 6]
    problems += [f"Relentless Strikes {spell} is no longer a dummy aura" for spell in relentless
                 if spells[spell][AURA] != SPELL_AURA_DUMMY]
    anesthetic = spells[ANESTHETIC_POISON]
    if anesthetic[BASE_POINTS] + 1 != 134:
        problems.append("Anesthetic Poison 1126688 no longer carries the rank 2 damage (134)")
    return check(len(ambush) == 10 and set(RELENTLESS_STRIKES) <= set(relentless) and not problems,
                 f"the client rows match what the fixes assume ({len(ambush)} Ambush ranks, {len(relentless)} Relentless "
                 "Strikes ranks)", problems)


def check_wiring():
    scripts = {(int(row[0]), row[1].strip("'")) for row in sql_rows("spell_script_names")}
    procs = {int(row[0]): [int(float(value)) for value in row[1:]] for row in sql_rows("spell_proc")}
    problems = [f"Crimson Tempest {spell} has no {name}" for spell in CRIMSON_TEMPEST
                for name in ("spell_ascension_reborn_crimson_tempest", "spell_ascension_reborn_crimson_tempest_bleed")
                if (spell, name) not in scripts]
    problems += [f"Poison Nova {spell} has no script" for spell in POISON_NOVA
                 if (spell, "spell_ascension_reborn_poison_nova") not in scripts]
    problems += ["Saber Slash has no script"] if (SABER_SLASH, "spell_ascension_reborn_saber_slash") not in scripts else []
    problems += [f"Savage Combat {spell} does not proc from poisons (Deadly Poison family flag)" for spell in SAVAGE_COMBAT
                 if procs.get(spell, [0] * 5)[1:4] != [8, 0, 524288]]
    rogue = source("src/server/scripts/Spells/spell_rogue.cpp")
    spree = body(rogue, "class spell_rog_killing_spree_aura : public AuraScript")
    problems += ["Killing Spree does not resolve the Reborn teleport, strike and buff twins"] if \
        spree.count("GetSpellTwinFor") < 4 else []
    spell = body(rogue, "class spell_rog_killing_spree : public SpellScript")
    problems += ["Killing Spree looks up the stock aura instead of its own"] if \
        "GetAura(SPELL_ROGUE_KILLING_SPREE)" in spell else []
    mechanics = source("src/server/coa/AscensionClassMechanics.cpp")
    problems += ["the Rogue contracts are not applied"] if \
        "ApplyAscensionWarcraftRebornRogueContracts(spellInfo);" not in mechanics else []
    return check(not problems, "Reborn Crimson Tempest, Poison Nova, Saber Slash, Savage Combat and Killing Spree run "
                 "against their own spells", problems)


CONTRACTS = r"""
#include <cassert>
#include <cmath>
#include <cstdint>
#include <initializer_list>
using uint8 = std::uint8_t;
using int32 = std::int32_t;
using uint32 = std::uint32_t;
enum SpellEffects : uint32 { SPELL_EFFECT_NONE = 0, SPELL_EFFECT_SCHOOL_DAMAGE = 2, SPELL_EFFECT_WEAPON_PERCENT_DAMAGE = 31,
    SPELL_EFFECT_NORMALIZED_WEAPON_DMG = 121 };
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_DUMMY = 4, SPELL_AURA_ADD_TARGET_TRIGGER = 109 };
enum SpellEffIndex { EFFECT_0 = 0, EFFECT_1 = 1, EFFECT_2 = 2 };
enum SpellFamilyNames : uint32 { SPELLFAMILY_ROGUE = 8 };
struct flag96
{
    uint32 part[3] = {};
    uint32& operator[](int index) { return part[index]; }
};
struct SpellEffectInfo
{
    uint32 Effect = SPELL_EFFECT_NONE;
    AuraType ApplyAuraName = SPELL_AURA_NONE;
    int32 BasePoints = 0;
    int32 DieSides = 0;
    float RealPointsPerLevel = 0;
    uint32 TriggerSpell = 0;
};
struct SpellInfo { uint32 Id = 0; uint32 SpellFamilyName = SPELLFAMILY_ROGUE; flag96 SpellFamilyFlags;
    SpellEffectInfo Effects[3]; };
namespace AscensionWarcraftReborn
{
constexpr uint32 REBORN_SPELL_OFFSET = 1100000;
"""


def check_contracts():
    source_ = source("src/server/coa/AscensionWarcraftRebornRogue.cpp")
    apply = body(source_, "void ApplyAscensionWarcraftRebornRogueContracts(SpellInfo* spellInfo)")
    if not apply:
        return check(False, "Ambush, Anesthetic Poison and Relentless Strikes match their tooltips",
                     ["no Warcraft Reborn rogue contracts"])
    constants = "\n".join(re.findall(r"^constexpr (?:uint8|uint32|int32|float) .*;", source_, re.M))
    code = CONTRACTS + constants + "\n}\n" + apply
    code += r"""
int main()
{
    SpellInfo ambush; ambush.Id = 1148691; ambush.SpellFamilyFlags[0] = 0x800200;
    ambush.Effects[0].Effect = SPELL_EFFECT_NORMALIZED_WEAPON_DMG; ambush.Effects[0].BasePoints = 382;
    ambush.Effects[1].Effect = SPELL_EFFECT_WEAPON_PERCENT_DAMAGE; ambush.Effects[1].BasePoints = 318;
    ApplyAscensionWarcraftRebornRogueContracts(&ambush);
    assert(std::lround((ambush.Effects[0].BasePoints + 1) * 3.19) == std::lround(383 * 2.75));
    SpellInfo poison; poison.Id = 1126688;
    poison.Effects[0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE; poison.Effects[0].BasePoints = 133; poison.Effects[0].DieSides = 39;
    ApplyAscensionWarcraftRebornRogueContracts(&poison);
    assert(poison.Effects[0].BasePoints + 1 == 68 && poison.Effects[0].BasePoints + poison.Effects[0].DieSides == 86);
    for (uint32 id : { 1114179u, 1158422u, 1158423u, 1158424u, 1158425u })
    {
        SpellInfo relentless; relentless.Id = id;
        relentless.Effects[0].ApplyAuraName = SPELL_AURA_DUMMY; relentless.Effects[0].TriggerSpell = 1114181;
        ApplyAscensionWarcraftRebornRogueContracts(&relentless);
        assert(relentless.Effects[0].ApplyAuraName == SPELL_AURA_ADD_TARGET_TRIGGER);
    }
    SpellInfo stock = ambush; stock.Id = 48691; stock.Effects[0].BasePoints = 382;
    ApplyAscensionWarcraftRebornRogueContracts(&stock);
    assert(stock.Effects[0].BasePoints == 382);
}
"""
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-reborn-rogue-") as directory:
        out = Path(directory)
        cpp, exe = out / "contracts.cpp", out / ("contracts.exe" if os.name == "nt" else "contracts")
        cpp.write_text(code, encoding="utf-8")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", str(cpp), "/Fe" + str(exe)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        ok = subprocess.run([str(exe)], cwd=out).returncode == 0
    return check(ok, "Ambush adds its flat bonus x2.75, Anesthetic Poison deals 68 to 86, and Relentless Strikes rolls "
                 "on finishing moves")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = (args.dbc_dir or dbc_dir()).resolve()
    spells, data, base = read_dbc(directory / "Spell.dbc")
    results = [check_tooltips(spells, data, base), check_wiring(), check_contracts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
