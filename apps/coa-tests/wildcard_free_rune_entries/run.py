CLI_DESCRIPTION = """Check that Wildcard counts each ability at its own essence cost and never rolls the free rune entries.

The ten Runeforge rune entries cost 0 Wildcard ability essence in CharacterAdvancement.dbc (dword 22) and name
Runeforging Mastery as their parent. The client sums each entry's own cost (Extensions.dll Build::GlobalAE), so a
rolled rune left 2 essence the client showed as a roll the server then refused with ROLL_ABILITIES_NO_ROLL (#6442,
#6883, #6867). This reads the client data (--dbc-dir), compiles the server's SpentEssence and PoolLevel, and checks
that the roll pool skips free entries. Needs a C++20 compiler; no database, server build or game client.
"""

import argparse
import os
from pathlib import Path
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
WILDCARD_AE, TYPE, PARENT, NAME, LEAGUE = 0x58, 4, 8, 188, 485
RUNEFORGING_MASTERY = 41942

failures = 0


def check(value, name):
    global failures
    failures += not value
    print(("PASS" if value else "FAIL") + ": " + name)


def free_entries(directory):
    raw = (directory / "CharacterAdvancement.dbc").read_bytes()
    count, _, size, _ = struct.unpack_from("<4I", raw, 4)
    strings = raw[20 + count * size:]
    text = lambda offset: strings[offset:strings.index(b"\0", offset)].decode("utf-8", "replace")
    rows = []
    for index in range(count):
        row = raw[20 + index * size:20 + (index + 1) * size]
        u32 = lambda offset: struct.unpack_from("<I", row, offset)[0]
        if row[LEAGUE] and text(u32(TYPE)) in ("Ability", "TalentAbility") and u32(WILDCARD_AE) == 0:
            rows.append((u32(0), text(u32(NAME)), u32(PARENT)))
    return rows


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()

    free = free_entries(args.dbc_dir or dbc_dir())
    check(len(free) == 10 and all(name.startswith("Rune of") and parent == RUNEFORGING_MASTERY
                                  for _, name, parent in free),
          "the ten free Wildcard abilities are the Runeforge runes under Runeforging Mastery")

    source = (ROOT / "src/server/coa/AscensionWildcard.cpp").read_text(encoding="utf-8")
    pool = source[source.index("auto const eligible = [&](Entry const& entry)"):]
    pool = pool[:pool.index("};")]
    check("(entry.Talent || entry.AbilityCost)" in pool, "the roll pool skips abilities that cost no essence")

    harness = (HERE / "harness.cpp").read_text(encoding="utf-8")
    for marker, text in [
        ("STRUCT_SPENT", method(source, "struct Spent") + ";"),
        ("SPENT_ESSENCE", method(source, "Spent SpentEssence(")),
        ("POOL_LEVEL", method(source, "std::optional<std::uint32_t> PoolLevel(")),
    ]:
        harness = harness.replace("// ACTUAL_" + marker, text)

    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler."
    with tempfile.TemporaryDirectory(prefix="coa-wildcard-free-runes-") as directory:
        out = Path(directory)
        (out / "harness.cpp").write_text(harness, encoding="utf-8")
        executable = out / ("regressions.exe" if os.name == "nt" else "regressions")
        if Path(compiler).stem.lower() == "cl":
            command = [compiler, "/nologo", "/std:c++20", "/EHsc", str(out / "harness.cpp"), f"/Fe:{executable}"]
        else:
            command = [compiler, "-std=c++20", str(out / "harness.cpp"), "-o", str(executable)]
        subprocess.run(command, check=True, cwd=out)
        result = subprocess.run([str(executable)], capture_output=True, text=True)
        print(result.stdout, end="")
        check(result.returncode == 0, "the server's essence accounting matches the client's")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
