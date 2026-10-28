CLI_DESCRIPTION = """Check Hellfire Imp initialization against the native neutral-target and immunity checks."""
import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile
import textwrap
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]

CASES = r"""
struct Player : Unit {};
struct Creature : Unit
{
    uint32 creator = 0;
    void SetCreatorGUID(uint32 owner) { creator = owner; }
    struct Threat
    {
        void RegisterRedirectThreat(uint32 spell, uint32 owner, uint32 percent)
        {
            assert(spell == 706571 && owner == 1 && percent == 100);
        }
    } threat;
    Threat& GetThreatMgr() { return threat; }
};
struct StateData { std::vector<uint32> imps; } state;
StateData& State(Player*) { return state; }
void Cast(Player*, Creature*, uint32 spell) { assert(spell == 800443); }
void Initialize(Creature* me, Player* player)
{
    uint32 owner = 1;
    // ACTUAL_IMP
}
int main()
{
    Player player;
    player.pvp = 5;
    Unit neutral;
    Creature imp;
    imp.entry = 50301;
    assert(!imp.NativeAttackAdmission(&neutral));
    Initialize(&imp, &player);
    assert(imp.creator == 1);
    assert(imp.m_ControlledByPlayer && imp.HasUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED));
    assert(imp.pvp == player.pvp);
    assert(imp.NativeAttackAdmission(&neutral));
    neutral.immuneNPC = true;
    assert(imp.NativeAttackAdmission(&neutral));
    neutral.immunePC = true;
    assert(!imp.NativeAttackAdmission(&neutral));
    neutral.immunePC = neutral.immuneNPC = false;
    neutral.flags = UNIT_FLAG_NON_ATTACKABLE;
    assert(!imp.NativeAttackAdmission(&neutral));
    for (uint32 entry : {50375u, 50268u, 51323u})
    {
        Creature other;
        other.entry = entry;
        Initialize(&other, &player);
        assert(!other.creator);
        assert(!other.m_ControlledByPlayer && !other.flags && !other.pvp);
    }
}
"""


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Use older Imp initialization as a negative control.")
    args = parser.parse_args()
    path = "src/server/coa/AscensionXorothSummons.cpp"
    source = (git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode("utf-8")
              if args.source_ref else (ROOT / path).read_text(encoding="utf-8"))
    initialization = method(source, "void IsSummonedBy(WorldObject* summoner)")
    imp = method(initialization, "if (me->GetEntry() == 50301)")
    unit = (ROOT / "src/server/game/Entities/Unit/Unit.cpp").read_text(encoding="utf-8")
    attack = method(unit, "bool Unit::_IsValidAttackTarget(")
    start = attack.index("    if (target->HasUnitFlag(UNIT_FLAG_NON_ATTACKABLE")
    attack = attack[start:attack.index("    ReputationRank repThisToTarget", start)]
    harness = (HERE.parent / "tinker_sentry/harness.cpp").read_text(encoding="utf-8")
    harness = harness[:harness.index("// ACTUAL_TIMER")].replace("// ACTUAL_ADMISSION", textwrap.indent(attack, "    "))
    harness += CASES.replace("// ACTUAL_IMP", imp)
    for name in ("RANGED_ATTACK", "CURRENT_AUTOREPEAT_SPELL", "SPELL_AURA_MOD_PACIFY"):
        harness = harness.replace("constexpr uint32 " + name, "[[maybe_unused]] constexpr uint32 " + name)
    compiler = shutil.which(os.environ.get("CXX", "g++"))
    assert compiler, "Set CXX to a C++20 compiler."
    with tempfile.TemporaryDirectory(prefix="coa-hellfire-imp-") as directory:
        out = Path(directory)
        cpp, exe = out / "imp.cpp", out / "imp.exe"
        cpp.write_text(harness, encoding="utf-8")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", str(cpp), "/Fe" + str(exe)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        subprocess.run([str(exe)], cwd=out, check=True)
    print("PASS: Imp creator, control flags, neutral-target admission, PC/NPC immunities, PvP state and other summons")


if __name__ == "__main__":
    main()
