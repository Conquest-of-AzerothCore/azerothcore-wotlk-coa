CLI_DESCRIPTION = """Exercise the Classic+ combat rules in the production melee roll, miss, resist and glancing code.

Expected values are vanilla 1.12 numbers (vmangos and the Turtle WoW 1.12 server), not outputs of this code.
Pass --source-ref to run the same checks against Unit.cpp from an earlier revision.
"""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
UNIT = "src/server/game/Entities/Unit/Unit.cpp"
FALLBACKS = {
    "static bool IsClassicPlusCombat(":
        "[[maybe_unused]] static bool IsClassicPlusCombat(Unit const*, Unit const*)\n{\n    return false;\n}\n",
    "static float ClassicCreatureAvoidanceChance(":
        "[[maybe_unused]] static float ClassicCreatureAvoidanceChance(Unit const*, AuraType)\n{\n    return 0.0f;\n}\n",
}
UNSCALED_SHOWN_LEVEL = ("static uint8 ShownCombatLevel(Unit const* unit, Unit const*)\n"
                        "{\n    return unit->GetLevel();\n}\n")


def compile_and_run(code):
    vc_tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(vc_tools) / "bin/Hostx64/x64/cl.exe") if vc_tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler (VS Developer PowerShell on Windows).")
    with tempfile.TemporaryDirectory(prefix="coa-classic-combat-") as directory:
        out = Path(directory)
        cpp, executable = out / "cases.cpp", out / ("cases.exe" if os.name == "nt" else "cases")
        cpp.write_text(code, encoding="utf-8")
        flags = (["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", str(cpp), "/Fe" + str(executable)]
                 if Path(compiler).stem.lower() == "cl" else
                 ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        return subprocess.run([str(executable)], cwd=out, timeout=60, capture_output=True, text=True)


def check_wiring(unit):
    armor = method(unit, "uint32 Unit::CalcArmorReducedDamage(")
    assert "ClassicPlusCombat::ArmorConstant(attacker->getLevelForTarget(victim))" in armor
    assert "ClassicPlusCombat::ArmorConstant(victim->getLevelForTarget(attacker))" in armor
    absorb = method(unit, "void Unit::CalcAbsorbResist(")
    assert "ClassicPlusCombat::PartialResistDistribution(averageResist)" in absorb
    assert "dmgInfo.GetDamageType() == DOT" in absorb and "DotResistChanceFactor" in absorb
    magic = method(unit, "SpellMissInfo Unit::MagicSpellHitResult(")
    assert "ClassicPlusCombat::BinaryResistChance(tmp, resistChance)" in magic
    assert "ClassicPlusCombat::EnergyThreatPerPoint" in method(unit, "void Unit::EnergizeBySpell(")
    assert "ClassicPlusCombat::DazeChancePerSkillPoint" in method(unit, "void Unit::DealMeleeDamage(")
    assert "CreatureVictimCritModifier(" in method(unit, "float Unit::GetUnitCriticalChance(")
    assert "CreatureVictimCritModifier(" in method(unit, "float Unit::SpellTakenCritChance(")
    special = method(unit, "SpellMissInfo Unit::MeleeSpellHitResult(")
    for avoidance, aura in (("Dodge", "SPELL_AURA_MOD_DODGE_PERCENT"), ("Parry", "SPELL_AURA_MOD_PARRY_PERCENT")):
        assert f"classicAvoidance(Avoidance::{avoidance}, ClassicCreatureAvoidanceChance(victim, {aura}))" in special
    assert "classicAvoidance(Avoidance::Block" in special
    assert "ClassicPlusCombat::Avoidance::Block" in method(unit, "bool Unit::isSpellBlocked(")
    wrapper = method(unit, "MeleeHitOutcome Unit::RollMeleeOutcomeAgainst(Unit const* victim, "
                           "WeaponAttackType attType) const")
    assert "ClassicCreatureAvoidanceChance(victim, SPELL_AURA_MOD_PARRY_PERCENT)" in wrapper


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Read Unit.cpp from a local Git revision to show the regression.")
    args = parser.parse_args()
    unit = (git_source(["git", "show", f"{args.source_ref}:{UNIT}"], cwd=ROOT).decode()
            if args.source_ref else ROOT.joinpath(UNIT).read_text(encoding="utf-8"))
    unit_header = ROOT.joinpath("src/server/game/Entities/Unit/Unit.h").read_text(encoding="utf-8")
    shared = ROOT.joinpath("src/server/shared/SharedDefines.h").read_text(encoding="utf-8")
    classic = ROOT.joinpath("src/server/game/Entities/Unit/ClassicPlusCombat.h").read_text(encoding="utf-8")

    enums = "".join(method(unit_header, "enum " + name) + ";\n" for name in ("WeaponAttackType", "MeleeHitOutcome"))
    enums += method(shared, "enum Classes\n") + ";\n"
    enums += re.search(r"^#define CLASSMASK_WAND_USERS .*$", shared, re.M)[0] + "\n"
    enums += method(shared, "constexpr Classes GetLegacyClassForCustomClass(") + "\n"

    methods = UNSCALED_SHOWN_LEVEL if "static uint8 ShownCombatLevel(" in unit else ""
    methods += "".join(method(unit, signature) + "\n" if signature in unit else fallback
                       for signature, fallback in FALLBACKS.items())
    for signature in ("MeleeHitOutcome Unit::RollMeleeOutcomeAgainst(Unit const* victim, WeaponAttackType attType, "
                      "int32 crit_chance", "float Unit::MeleeSpellMissChance(",
                      "float Unit::GetEffectiveResistChance("):
        methods += method(unit, signature) + "\n"
    glancing = method(method(unit, "void Unit::CalculateMeleeDamage("), "case MELEE_HIT_GLANCING:")

    code = (HERE / "harness.cpp").read_text(encoding="utf-8")
    code = code.replace("// NATIVE_ENUMS", enums)
    code = code.replace("// SOURCE", re.sub(r"^#include.*\n", "", classic, flags=re.M))
    code = code.replace("// METHODS", methods)
    code = code.replace("// NATIVE_GLANCING", glancing)
    result = compile_and_run(code)
    assert result.returncode == 0, result.stdout + result.stderr
    if not args.source_ref:
        check_wiring(unit)
    print("PASS: vanilla melee table, crushing gate, glancing bounds, miss, armor, resist and spell-hit rules; "
          "level 61-80 and rules-off paths keep WotLK values")


if __name__ == "__main__":
    main()
