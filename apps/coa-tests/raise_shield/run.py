CLI_DESCRIPTION = """Execute Raise Shield's production block callback and energize correction in a native fixture."""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402
from client_data import dbc_dir  # noqa: E402


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Test a local Git revision to demonstrate the regression.")
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()

    def source(path):
        if args.source_ref:
            return git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
        return ROOT.joinpath(path).read_text(encoding="utf-8")

    mechanics = source("src/server/coa/AscensionClassMechanics.cpp")
    constants = "\n".join(re.findall(r"^constexpr (?:uint32|int32) (?:SPELL_GUARDIAN_|GUARDIAN_RAISE_SHIELD_).*;",
                                     mechanics, re.M))
    correction = method(mechanics, "if (spellInfo->Id == SPELL_GUARDIAN_RAISE_SHIELD_ENERGIZE)")
    callback = method(mechanics, "void HandleAscensionClassMechanicsBlock(")
    constants = "\n".join(line for line in constants.splitlines()
                          if re.search(r"\b" + line.split()[2] + r"\b", correction + callback))
    raw = args.dbc_dir.joinpath("Spell.dbc").read_bytes()
    magic, count, fields, size, _ = struct.unpack_from("<4s4I", raw)
    assert (magic, fields, size) == (b"WDBC", 234, 936)
    rows = {row[0]: row for row in struct.iter_unpack("<234I", raw[20:20 + count * size])}
    parent, energize = rows[500168], rows[500493]
    assert parent[34] == 0 and parent[96] == 42 and parent[117] == 500493
    assert (energize[71], energize[74], energize[110]) == (30, 1, 3)
    basepoints = struct.unpack("<i", struct.pack("<I", energize[80]))[0]
    code = r'''
#include <cassert>
#include <cstdint>
#include <set>
#include <vector>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
constexpr int CLASS_GUARDIAN=18, EFFECT_0=0, SPELL_EFFECT_ENERGIZE=30, POWER_ENERGY=3;
#define LOG_ERROR(...) ((void)0)
struct SpellEffectInfo { int Effect=30, MiscValue=3, BasePoints=19, DieSides=1; };
struct SpellInfo { uint32 Id=500493; SpellEffectInfo Effects[1]; };
struct Player
{
    int cls=18;
    std::set<uint32> auras, spells;
    std::vector<uint32> casts;
    int getClass() const { return cls; }
    bool HasAura(uint32 id) const { return auras.count(id)!=0; }
    bool HasSpell(uint32 id) const { return spells.count(id)!=0; }
    void CastSpell(Player* target, uint32 id, bool triggered)
    { assert(target==this && triggered); casts.push_back(id); }
};
''' + constants + "\nvoid Correct(SpellInfo* spellInfo) {\n" + correction + "\n}\n" + callback
    code += r'''
int main()
{
    SpellInfo spell;
    spell.Effects[0].BasePoints = INSTALLED_BASE_POINTS;
    Correct(&spell);
    assert(spell.Effects[0].BasePoints + spell.Effects[0].DieSides == 20);
    // Also normalize a previously patched 30-Energy helper, without guessing at unrelated metadata.
    spell.Effects[0].BasePoints=29;
    Correct(&spell);
    assert(spell.Effects[0].BasePoints==19);
    spell.Effects[0].MiscValue=0;
    spell.Effects[0].BasePoints=29;
    Correct(&spell);
    assert(spell.Effects[0].BasePoints==29);
    Player player;
    HandleAscensionClassMechanicsBlock(nullptr);
    HandleAscensionClassMechanicsBlock(&player);
    assert(player.casts.empty());
    player.auras.insert(500168);
    // The callback has no damage requirement: both full and partial blocks receive one energize.
    HandleAscensionClassMechanicsBlock(&player);
    assert(player.casts==std::vector<uint32>{500493});
    HandleAscensionClassMechanicsBlock(&player);
    assert(player.casts==std::vector<uint32>({500493,500493}));
    player.casts.clear();
    player.cls=1;
    HandleAscensionClassMechanicsBlock(&player);
    assert(player.casts.empty());
    player.cls=18;
    player.auras.erase(500168);
    player.spells.insert(SPELL_GUARDIAN_REPRISAL);
    player.auras.insert(SPELL_GUARDIAN_VETERAN);
    player.auras.insert(SPELL_GUARDIAN_HONORABLE);
    HandleAscensionClassMechanicsBlock(&player);
    assert(player.casts==std::vector<uint32>({SPELL_GUARDIAN_REPRISAL_READY,
        SPELL_GUARDIAN_VETERAN_HEAL,SPELL_GUARDIAN_HONORABLE_EFFECTS}));
}
'''.replace("INSTALLED_BASE_POINTS", str(basepoints))
    vc_tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(vc_tools) / "bin/Hostx64/x64/cl.exe") if vc_tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler (VS Developer PowerShell on Windows).")
    with tempfile.TemporaryDirectory(prefix="coa-raise-shield-") as directory:
        out = Path(directory)
        cpp, executable = out / "cases.cpp", out / ("cases.exe" if os.name == "nt" else "cases")
        cpp.write_text(code, encoding="utf-8")
        flags = (["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", str(cpp), "/Fe" + str(executable)]
                 if Path(compiler).stem.lower() == "cl" else
                 ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)
    compat = source("src/server/coa/AscensionCompat.cpp")
    assert "HandleAscensionClassMechanicsDamageTaken" not in mechanics + compat
    assert "HandleAscensionClassMechanicsBlock(player);" in method(compat, "void OnBlock(Unit *victim")
    print("PASS: 20 Energy helper, block callback, aura/class guards, existing block procs, no damage callback")


if __name__ == "__main__":
    main()
