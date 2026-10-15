CLI_DESCRIPTION = """Check that Warcraft Reborn Paladin spells are wired to do what their own tooltips say."""

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
FAMILY_FLAGS, DESCRIPTION = 209, 170


def read_spells(dbc, wanted):
    data = (dbc / "Spell.dbc").read_bytes()
    count, fields, size, _ = struct.unpack_from("<4I", data, 4)
    text = 20 + count * size
    spells = {}
    for row in range(count):
        record = struct.unpack_from("<%dI" % fields, data, 20 + row * size)
        if record[0] in wanted:
            offset = record[DESCRIPTION]
            spells[record[0]] = (record, data[text + offset:data.index(b"\0", text + offset)].decode("utf-8", "replace"))
    return spells


def sql_rows(table):
    rows = []
    for path in sorted(PENDING.glob("rev_*.sql")):
        sql = path.read_text(encoding="utf-8")
        if not sql.startswith("-- Warcraft Reborn Paladin: Exorcism"):
            continue
        for block in re.findall(r"INSERT INTO `" + table + r"`[^;]*;", sql):
            rows += [row.split(", ") for row in re.findall(r"\(([^()]*)\)", block.split("VALUES", 1)[1])]
    return rows


def check(ok, text, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text}")
    for line in problems:
        print("  ", line)
    return ok


def check_exorcism(spells):
    tooltip = spells[1100879][1]
    direct = float(re.search(r"([\d.]+)\*\$SPH", tooltip).group(1))
    ap = float(re.search(r"([\d.]+)\*\$AP", tooltip).group(1))
    rows = {int(row[0]): (float(row[1]), float(row[3])) for row in sql_rows("spell_bonus_data")}
    return check(rows.get(1100879) == (direct, ap),
                 f"Reborn Exorcism scales with the {direct} spell power and {ap} attack power its tooltip gives")


def check_bindings():
    rows = {(int(row[0]), row[1].strip("'")) for row in sql_rows("spell_script_names")}
    wanted = {(-1120473, "spell_pal_holy_shock"), (1121084, "spell_pal_seal_of_righteousness"),
              (1120337, "spell_pal_heart_of_the_crusader")}
    source = (ROOT / "src/server/scripts/Spells/spell_paladin.cpp").read_text(encoding="utf-8")
    shock = method(source, "class spell_pal_holy_shock : public SpellScript")
    seal = method(source, "class spell_pal_seal_of_righteousness : public AuraScript")
    wise = method(source, "class spell_pal_judgements_of_the_wise : public AuraScript")
    problems = [f"missing binding {spell} {script}" for spell, script in sorted(wanted - rows)]
    problems += [f"{name} does not resolve the Reborn twin" for name, text in
                 (("Holy Shock", shock), ("Seal of Righteousness", seal), ("Judgements of the Wise", wise))
                 if "GetSpellTwinFor" not in text]
    problems += ["Holy Shock still rejects the Reborn chain"] if "GetSpellTwinSource(spellInfo->Id)" not in shock else []
    return check(not problems, "Reborn Holy Shock, Seal of Righteousness, Heart of the Crusader rank 3 and Judgements "
                 "of the Wise run their stock scripts against their own spells", problems)


def check_procs(spells):
    rows = {int(row[0]): [int(float(value)) for value in row[1:]] for row in sql_rows("spell_proc")}
    holy_light = spells[1100635][0][FAMILY_FLAGS]
    problems = []
    if rows.get(1121084, [0] * 6)[5] == 0:
        problems.append("Seal of Righteousness has no melee proc flags")
    if rows.get(-1131833, [0] * 3)[2] != holy_light:
        problems.append("Light's Grace does not proc from Holy Light's family flag")
    if rows.get(1120337) != rows.get(-20335, rows.get(1120337)):
        problems.append("Heart of the Crusader rank 3 differs from the stock proc row")
    return check(not problems, "Reborn Seal of Righteousness, Light's Grace and Heart of the Crusader rank 3 proc "
                 "from the events their tooltips name", problems)


CONTRACTS = r"""
#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
using uint32 = std::uint32_t;
enum AuraType { SPELL_AURA_NONE = 0, SPELL_AURA_MOD_THREAT = 10, SPELL_AURA_ADD_FLAT_MODIFIER = 107,
    SPELL_AURA_ADD_PCT_MODIFIER = 108 };
enum SpellEffIndex { EFFECT_0 = 0 };
struct flag96
{
    uint32 part[3] = {};
    uint32& operator[](int index) { return part[index]; }
    explicit operator bool() const { return part[0] || part[1] || part[2]; }
};
struct SpellEffectInfo { AuraType ApplyAuraName = SPELL_AURA_NONE; float RealPointsPerLevel = 0; flag96 SpellClassMask; };
struct SpellInfo { uint32 Id = 0; std::array<SpellEffectInfo, 3> Effects; };
namespace AscensionWarcraftReborn
{
"""


def check_contracts():
    source = (ROOT / "src/server/coa/AscensionWarcraftRebornPaladin.cpp").read_text(encoding="utf-8")
    constants = "\n".join(re.findall(r"^constexpr .*(?:RIGHTEOUS_FURY|HEALING_LIGHT|SANCTIFIED_LIGHT|_FLAG) = .*;$",
                                     source, re.M))
    code = CONTRACTS + constants + "\n" + method(source, "bool IsOneOf(") + "\n}\n"
    code += method(source, "void ApplyAscensionWarcraftRebornPaladinContracts(SpellInfo* spellInfo)")
    code += r"""
int main()
{
    SpellInfo fury; fury.Id = 1125780;
    fury.Effects[0].ApplyAuraName = SPELL_AURA_MOD_THREAT; fury.Effects[0].RealPointsPerLevel = 0.5f;
    fury.Effects[2].ApplyAuraName = SPELL_AURA_MOD_THREAT; fury.Effects[2].RealPointsPerLevel = 0.5f;
    ApplyAscensionWarcraftRebornPaladinContracts(&fury);
    assert(fury.Effects[0].RealPointsPerLevel == 0 && fury.Effects[2].RealPointsPerLevel == 0);
    for (uint32 id : { 1120237u, 1120238u, 1120239u })
    {
        SpellInfo light; light.Id = id; light.Effects[0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        light.Effects[0].SpellClassMask[0] = 0xC0000000;
        ApplyAscensionWarcraftRebornPaladinContracts(&light);
        assert(light.Effects[0].SpellClassMask[0] == 0xC0200000);
    }
    for (uint32 id : { 1120359u, 1120360u, 1120361u })
    {
        SpellInfo sanctified; sanctified.Id = id; sanctified.Effects[0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
        ApplyAscensionWarcraftRebornPaladinContracts(&sanctified);
        assert(sanctified.Effects[0].SpellClassMask[0] == 0x80200000);
    }
    SpellInfo stock; stock.Id = 20237; stock.Effects[0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    ApplyAscensionWarcraftRebornPaladinContracts(&stock);
    assert(!stock.Effects[0].SpellClassMask);
}
"""
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-reborn-paladin-") as directory:
        out = Path(directory)
        cpp, exe = out / "contracts.cpp", out / ("contracts.exe" if os.name == "nt" else "contracts")
        cpp.write_text(code, encoding="utf-8")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", str(cpp), "/Fe" + str(exe)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        ok = subprocess.run([str(exe)], cwd=out).returncode == 0
    return check(ok, "Righteous Fury keeps its tooltip's 75%, and Healing Light and Sanctified Light reach Holy Shock "
                 "and Holy Light")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    spells = read_spells((args.dbc_dir or dbc_dir()).resolve(), {1100879, 1100635})
    results = [check_exorcism(spells), check_bindings(), check_procs(spells), check_contracts()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
