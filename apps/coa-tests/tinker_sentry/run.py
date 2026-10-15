CLI_DESCRIPTION = """Exercise Sentry initialization, native attack admission, firing and model scale.

Uses actual source blocks with bounded world/visibility/cast transport dependencies.
No server build, database service, installed files or gameplay state is changed.
"""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import sqlite3
import subprocess
import tempfile
import textwrap
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Read C++ from a local Git ref to reproduce the pre-fix failure.")
    args = parser.parse_args()

    def source(path):
        if args.source_ref:
            return git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
        return (ROOT / path).read_text(encoding="utf-8")

    summons = source("src/server/coa/AscensionTinkerSummons.cpp")
    tinker = source("src/server/coa/AscensionTinker.cpp")
    unit = source("src/server/game/Entities/Unit/Unit.cpp")
    initialization = method(summons, "void IsSummonedBy(WorldObject* summoner)")
    initialization = initialization[:initialization.index("        me->SetReactState")] + "}"
    initialization = initialization.replace(" override", "")
    attack = method(unit, "bool Unit::_IsValidAttackTarget(")
    start = attack.index("    if (target->HasUnitFlag(UNIT_FLAG_NON_ATTACKABLE")
    attack = attack[start:attack.index("    ReputationRank repThisToTarget", start)]
    harness = (HERE / "harness.cpp").read_text(encoding="utf-8")
    for marker, code in (
        ("INITIALIZATION", initialization),
        ("ADMISSION", textwrap.indent(attack, "    ")),
        ("TIMER", method(unit, "void Unit::resetAttackTimer(")),
        ("TURRET", method(summons, "bool Turret(")),
        ("NOTIFY_ATTACK", method(tinker, "bool NotifyAttack(")),
        ("NOTIFY_SPELL_ATTACK", method(tinker, "bool NotifySpellAttack(")),
        ("OBSERVE_ATTACK", method(tinker, "void ObserveAttack(")),
        ("TARGET", method(summons, "Unit* TurretTarget(")),
        ("UPDATE", method(summons, "void UpdateTurret(")),
    ):
        harness = harness.replace("// ACTUAL_" + marker, code)

    vc_tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(vc_tools) / "bin/Hostx64/x64/cl.exe") if vc_tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler (VS Developer PowerShell on Windows).")
    with tempfile.TemporaryDirectory(prefix="tinker-sentry-") as directory:
        out = Path(directory)
        cpp = out / "harness.cpp"
        cpp.write_text(harness, encoding="utf-8")
        executable = out / ("sentry.exe" if os.name == "nt" else "sentry")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                     str(cpp), "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        subprocess.run([str(executable)], cwd=out, check=True)

    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260913_00_tinker_sentry.sql").read_text()
    with sqlite3.connect(":memory:") as db:
        db.executescript("""
            CREATE TABLE creature_template_model (
                CreatureID INT, Idx INT, CreatureDisplayID INT, DisplayScale REAL, Probability REAL,
                PRIMARY KEY (CreatureID, Idx));
            INSERT INTO creature_template_model VALUES
                (50046, 0, 28526, 1, 1), (50046, 1, 12345, 0.8, 0), (999, 0, 28526, 2, 1);
        """)
        expected = [(999, 0, 28526, 2.0, 1.0), (50046, 0, 28526, 0.35, 1.0), (50046, 1, 12345, 0.8, 0.0)]
        for _ in range(2):
            db.executescript(sql)
            assert list(db.execute("SELECT * FROM creature_template_model ORDER BY CreatureID, Idx")) == expected
    print("PASS: Sentry control flags, native shot admission, targeting, timers and scoped model-scale migration")


if __name__ == "__main__":
    main()
