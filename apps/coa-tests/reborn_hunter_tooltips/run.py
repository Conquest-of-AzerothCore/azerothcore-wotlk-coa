CLI_DESCRIPTION = """Check that Warcraft Reborn Hunter spells are wired to do what their own tooltips say."""

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
REBORN_SPELL_OFFSET = 1100000
DURATION, EFFECT, AMPLITUDE, MISC_VALUE, DESCRIPTION, FAMILY = 40, 71, 98, 110, 170, 208
SUMMON_OBJECT_EFFECTS = {50, 104, 105, 106, 107}
SERPENT_STING, BLACK_ARROW, QUICK_SHOT = 1101978, 1103674, 1121004


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
        if not sql.startswith("-- Warcraft Reborn Hunter: traps"):
            continue
        for block in re.findall(r"INSERT INTO `" + table + r"`[^;]*;", sql):
            values = block.split("VALUES", 1)[1].split("ON DUPLICATE KEY UPDATE", 1)[0]
            rows += [row.split(", ") for row in re.findall(r"\(([^()]*)\)", values)]
    return rows


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def check_traps(spells):
    objects = {}
    for spell_id, record in spells.items():
        stock = spells.get(spell_id - REBORN_SPELL_OFFSET)
        if spell_id < REBORN_SPELL_OFFSET or record[FAMILY] != 9 or not stock:
            continue
        for effect in range(3):
            entry = record[MISC_VALUE + effect]
            if record[EFFECT + effect] in SUMMON_OBJECT_EFFECTS and stock[MISC_VALUE + effect] == entry - 1000000:
                objects.setdefault(entry, spell_id)
    rows = {int(row[0]): int(row[11]) for row in sql_rows("gameobject_template")}
    addons = {int(row[0]) for row in sql_rows("gameobject_template_addon")}
    problems = [f"spell {spell} places gameobject {entry}, which has no template" for entry, spell in
                sorted(objects.items()) if entry not in rows]
    problems += [f"gameobject {entry} has no template addon" for entry in sorted(objects) if entry not in addons]
    problems += [f"gameobject {entry} fires {rows[entry]}, not a Reborn spell" for entry in sorted(objects)
                 if entry in rows and (rows[entry] < REBORN_SPELL_OFFSET or rows[entry] not in spells)]
    return check(bool(objects) and not problems, f"all {len(objects)} Reborn hunter traps place an object that fires a "
                 "Reborn trap spell", problems)


def check_scaling(spells, durations, data, base):
    rows = {int(row[0]): [float(value) for value in row[1:5]] for row in sql_rows("spell_bonus_data")}
    problems = []
    for spell_id in (SERPENT_STING, BLACK_ARROW):
        record = spells[spell_id]
        tooltip = float(re.search(r"\$RAP\*([\d.]+)", text(data, base, record[DESCRIPTION])).group(1))
        ticks = durations[record[DURATION]][1] // max(record[AMPLITUDE:AMPLITUDE + 3])
        if abs(rows.get(spell_id, [0] * 4)[3] - tooltip / ticks) > 1e-6:
            problems.append(f"{spell_id} periodic attack power share is not {tooltip} over {ticks} ticks")
    tooltip = float(re.search(r"\$RAP\*([\d.]+)", text(data, base, spells[QUICK_SHOT][DESCRIPTION])).group(1))
    if abs(rows.get(QUICK_SHOT, [0] * 4)[2] - tooltip) > 1e-6:
        problems.append(f"{QUICK_SHOT} attack power share is not {tooltip}")
    return check(not problems, "Reborn Serpent Sting, Black Arrow and Quick Shot scale with the ranged attack power "
                 "their tooltips give", problems)


def check_wiring():
    links = {(int(row[0]), int(row[1])) for row in sql_rows("spell_linked_spell")}
    scripts = {(int(row[0]), row[1].strip("'")) for row in sql_rows("spell_script_names")}
    procs = {int(row[0]): [int(float(value)) for value in row[1:]] for row in sql_rows("spell_proc")}
    hunter = source("src/server/scripts/Spells/spell_hunter.cpp")
    beast = body(hunter, "class spell_hun_aspect_of_the_beast : public AuraScript")
    effects = source("src/server/game/Spells/SpellEffects.cpp")
    steady = effects[effects.find("// Steady Shot"):effects.find("// Add Ammo and Weapon damage plus RAP * 0.1")]
    problems = [f"Aspect of the Dragonhawk {spell} does not apply the Reborn dodge 1161848"
                for spell in (1161846, 1161847) if (spell, 1161848) not in links]
    problems += [f"Piercing Shots {spell} has no script" for spell in (1153234, 1153237, 1153238)
                 if (spell, "spell_hun_piercing_shots") not in scripts]
    problems += [f"Piercing Shots {spell} procs on more than critical hits" for spell in (1153234, 1153237, 1153238)
                 if procs.get(spell, [0] * 9)[8] != 2]
    problems += [f"{spell} does not proc from Auto Shot" for spell in (-1113165, -1161846)
                 if procs.get(spell, [0] * 6)[5] != 64]
    problems += ["Aspect of the Beast does not resolve the Reborn twin"] if "GetSpellTwinSource" not in beast or \
        "GetSpellTwinFor" not in beast else []
    problems += ["Steady Shot adds weapon damage on top of a weapon percent effect"] if \
        "HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE)" not in steady else []
    return check(not problems, "Reborn Aspect of the Dragonhawk, Aspect of the Hawk, Aspect of the Beast, Piercing Shots "
                 "and Steady Shot run against their own spells", problems)


CONTRACTS = r"""
#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
using uint8 = std::uint8_t;
using int32 = std::int32_t;
using uint32 = std::uint32_t;
enum SpellEffects : uint32 { SPELL_EFFECT_NONE = 0, SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL = 17,
    SPELL_EFFECT_WEAPON_PERCENT_DAMAGE = 31, SPELL_EFFECT_WEAPON_DAMAGE = 58, SPELL_EFFECT_NORMALIZED_WEAPON_DMG = 121 };
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_PROC_TRIGGER_SPELL = 42, SPELL_AURA_ADD_FLAT_MODIFIER = 107,
    SPELL_AURA_ADD_PCT_MODIFIER = 108 };
enum SpellEffIndex { EFFECT_0 = 0, EFFECT_1 = 1, EFFECT_2 = 2 };
enum SpellFamilyNames : uint32 { SPELLFAMILY_HUNTER = 9 };
constexpr uint8 MAX_SPELL_EFFECTS = 3;
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
    float RealPointsPerLevel = 0;
    uint32 TriggerSpell = 0;
    flag96 SpellClassMask;
};
struct SpellInfo { uint32 Id = 0; uint32 SpellFamilyName = SPELLFAMILY_HUNTER; uint32 ProcChance = 0;
    std::array<SpellEffectInfo, 3> Effects; };
namespace AscensionWarcraftReborn
{
constexpr uint32 REBORN_SPELL_OFFSET = 1100000;
"""


def check_contracts():
    source_ = source("src/server/coa/AscensionWarcraftRebornHunter.cpp")
    apply = body(source_, "void ApplyAscensionWarcraftRebornHunterContracts(SpellInfo* spellInfo)")
    if not apply:
        return check(False, "Aimed Shot, Mortal Shots, Hawk Eye and Improved Steady Shot rank 3 match their tooltips",
                     ["no Warcraft Reborn hunter contracts"])
    constants = "\n".join(re.findall(r"^constexpr .*;$", source_, re.M))
    code = CONTRACTS + constants + "\n" + body(source_, "template <std::size_t N>") + "\n"
    code += body(source_, "bool IsFlatWeaponBonus(") + "\n" + body(source_, "void KeepFlatBonusOutsideWeaponPercent(")
    code += "\n}\n" + apply
    code += r"""
int main()
{
    SpellInfo aimed; aimed.Id = 1149050;
    aimed.Effects[0].Effect = SPELL_EFFECT_NORMALIZED_WEAPON_DMG; aimed.Effects[0].BasePoints = 454;
    aimed.Effects[2].Effect = SPELL_EFFECT_WEAPON_PERCENT_DAMAGE; aimed.Effects[2].BasePoints = 144;
    ApplyAscensionWarcraftRebornHunterContracts(&aimed);
    assert(std::lround((aimed.Effects[0].BasePoints + 1) * 1.45) == 455);
    for (uint32 id : { 1119485u, 1119487u, 1119488u, 1119489u, 1119490u })
    {
        SpellInfo shots; shots.Id = id;
        shots.Effects[0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER; shots.Effects[0].BasePoints = 6;
        shots.Effects[1].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER; shots.Effects[1].BasePoints = 12;
        ApplyAscensionWarcraftRebornHunterContracts(&shots);
        assert((shots.Effects[0].SpellClassMask[0] & 0x1) && shots.Effects[1].BasePoints == 6);
    }
    for (uint32 id : { 1119498u, 1119499u, 1119500u })
    {
        SpellInfo eye; eye.Id = id; eye.Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
        ApplyAscensionWarcraftRebornHunterContracts(&eye);
        assert(eye.Effects[0].SpellClassMask[1] & 0x00800000);
    }
    SpellInfo steady; steady.Id = 1153224; steady.ProcChance = 100;
    steady.Effects[0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL; steady.Effects[0].BasePoints = 14;
    ApplyAscensionWarcraftRebornHunterContracts(&steady);
    assert(steady.ProcChance == 15 && steady.Effects[0].TriggerSpell == 1153220);
    SpellInfo stock = aimed; stock.Id = 49050; stock.Effects[0].BasePoints = 454;
    ApplyAscensionWarcraftRebornHunterContracts(&stock);
    assert(stock.Effects[0].BasePoints == 454);
}
"""
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-reborn-hunter-") as directory:
        out = Path(directory)
        cpp, exe = out / "contracts.cpp", out / ("contracts.exe" if os.name == "nt" else "contracts")
        cpp.write_text(code, encoding="utf-8")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", str(cpp), "/Fe" + str(exe)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        ok = subprocess.run([str(exe)], cwd=out).returncode == 0
    return check(ok, "Aimed Shot keeps its flat bonus outside the weapon percent, Mortal Shots and Hawk Eye reach the "
                 "shots their tooltips name, and Improved Steady Shot rank 3 has a 15% chance")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = (args.dbc_dir or dbc_dir()).resolve()
    spells, data, base = read_dbc(directory / "Spell.dbc")
    durations = read_dbc(directory / "SpellDuration.dbc")[0]
    results = [check_traps(spells), check_scaling(spells, durations, data, base), check_wiring(),
               check_contracts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
