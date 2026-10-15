CLI_DESCRIPTION = """Exercise the actual restored selector and aura callbacks with bounded game APIs.

Checks the pending SQL and matching client DBC transformation in memory. Native
combat, inventory, aura dispatch and packet transport are not simulated servers.
"""
import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import sqlite3
import struct
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def check_data(path):
    client = runpy.run_path(str(ROOT / "apps/coa-spells/primal_weapons.py"))
    if path:
        raw = path.read_bytes()
    else:
        row = [0] * 234
        row[0], row[4], row[71], row[95], row[208] = 537218, 192, 6, 4, 37
        sentinel = [0] * 234
        sentinel[0] = 42
        raw = struct.pack("<4s4I", b"WDBC", 2, 234, 936, 1) + struct.pack("<468I", *row, *sentinel) + b"\0"
    patched = client["transform"](raw)
    assert client["transform"](patched) == patched
    count = struct.unpack_from("<I", raw, 4)[0]
    wanted = {537218, 801242, 704098, 563262, 806070, 806071}
    old = {}
    offset = None
    for index in range(count):
        start = 20 + index * 936
        sid = struct.unpack_from("<I", raw, start)[0]
        if sid in wanted:
            old[sid] = struct.unpack_from("<234I", raw, start)
        if sid == 537218:
            offset = start
    assert offset is not None
    new = {537218: struct.unpack_from("<234I", patched, offset)}
    before, after = memoryview(raw), memoryview(patched)
    assert before[20:offset] == after[20:offset]
    assert before[offset + 936:20 + count * 936] == after[offset + 936:20 + count * 936]
    assert {i for i, (a, b) in enumerate(zip(old[537218], new[537218])) if a != b} <= (
        set(client["EDITS"]) | {153, 170})
    assert not new[537218][4] & 192 and new[537218][71:74] == (3, 0, 0)
    assert new[537218][95] == 0 and new[537218][41] == 0 and new[537218][204] == 15
    if path:
        assert old[801242][69] == 41105 and old[704098][69] == 1378
        assert old[801242][204] == old[704098][204] == 15
        assert old[563262][95] == 108 and old[563262][80] + old[563262][74] == 25
        assert old[704098][95:98] == (166, 42, 24) and old[704098][100] == 5000
        assert old[806070][95] == old[806071][95] == 138
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260913_01_primal_weapons.sql").read_text()
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT)")
    db.execute("CREATE TABLE spell_proc (SpellId INT, SchoolMask INT, ProcFlags INT, SpellTypeMask INT, "
               "SpellPhaseMask INT, HitMask INT, DisableEffectsMask INT, Chance INT, Charges INT)")
    db.execute("INSERT INTO spell_script_names VALUES (42, 'unrelated')")
    db.execute("INSERT INTO spell_proc VALUES (42, 0, 0, 0, 0, 0, 0, 0, 0)")
    db.executescript(sql)
    first = list(db.iterdump())
    db.executescript(sql)
    assert list(db.iterdump()) == first
    assert db.execute("SELECT COUNT(*) FROM spell_script_names WHERE spell_id = 42").fetchone() == (1,)
    assert db.execute("SELECT ProcFlags, Charges FROM spell_proc WHERE SpellId = 806070").fetchone() == (4, 2)
    assert db.execute("SELECT ProcFlags, Charges FROM spell_proc WHERE SpellId = 806071").fetchone() == (4, 2)
    assert db.execute("SELECT HitMask, DisableEffectsMask FROM spell_proc WHERE SpellId = 801242").fetchone() == (2, 3)
    print("PASS: one-row client edit, idempotent SQL, native helper fields and two-charge proc data")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    check_data(args.spell_dbc)
    source = (ROOT / "src/server/coa/AscensionPrimalistWeapons.cpp").read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    source = source.replace(": public AuraScript\n{", ": public AuraScript\n{\npublic:")
    compat = (ROOT / "src/server/coa/AscensionCompat.cpp").read_text()
    eligible = method(compat, "bool IsAscensionPrimalistWeaponsEligible(")
    native = (ROOT / "src/server/game/Spells/Auras/SpellAuras.cpp").read_text()
    charges = "\n".join(method(native, signature) for signature in (
        "uint8 Aura::CalcMaxCharges(", "void Aura::PrepareProcToTrigger(", "void Aura::ConsumeProcCharges("))
    harness = (HERE / "harness.cpp").read_text().replace("// ACTUAL_ELIGIBILITY", eligible)
    harness = harness.replace("// ACTUAL_SOURCE", source).replace("// ACTUAL_CHARGES", charges)
    tools = os.environ.get("VCToolsInstallDir")
    compiler = (str(Path(tools) / "bin/Hostx64/x64/cl.exe") if tools else
                shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++")))
    if not compiler:
        raise RuntimeError("Enable a C++20 compiler")
    with tempfile.TemporaryDirectory(prefix="coa-primal-weapons-") as directory:
        out = Path(directory)
        cpp = out / "harness.cpp"
        cpp.write_text(harness, encoding="utf-8")
        exe = out / ("test.exe" if os.name == "nt" else "test")
        flags = (["/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8", str(cpp), "/Fe" + str(exe)]
                 if Path(compiler).stem.lower() == "cl" else
                 ["-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True)
        subprocess.run([str(exe)], cwd=out, check=True)


if __name__ == "__main__":
    main()
