CLI_DESCRIPTION = """Check that every creature a Warcraft Reborn class spell summons exists and acts as its stock pet.

Reads the client Spell.dbc (--dbc-dir) for the Reborn class spells (1100000 + the stock spell) that summon a creature,
then checks the pending world SQL creates each one whose stock creature exists, with the stock pet's family, models,
pet level stats and names, and that the core reads a Reborn copy as its stock entry (GetStockPetEntry).
No database, server build or game client is needed.
"""

import argparse
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402
from coa_talent_catalog import STUBS  # noqa: E402

OFFSET = 1100000
SUMMON_EFFECTS = {28, 41, 42, 56, 93, 97}
EFFECT, MISC = 71, 110
SQL = ROOT / "data/sql/updates/pending_db_world/rev_20261005_30_coa_warcraft_reborn_summons.sql"
UNSOURCED = {1165447, 1181421, 1211859, 1855350}
ALREADY_PRESENT = {1436401, 2110009, 2110014}
IMP, VOIDWALKER, WATER_ELEMENTAL = 1100416, 1101860, 1137994

MAIN = r"""
#include "PetDefines.h"
#include <cstdio>

int main()
{
    int failures = 0;
    auto check = [&failures](bool value, char const* name)
    {
        failures += !value;
        std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
    };
    check(GetStockPetEntry(1100416) == NPC_IMP && GetStockPetEntry(1117252) == NPC_FELGUARD &&
        GetStockPetEntry(1137994) == NPC_WATER_ELEMENTAL_PERM, "a Reborn summon reads as its stock pet");
    check(GetStockPetEntry(NPC_IMP) == NPC_IMP && GetStockPetEntry(1100000) == 1100000 &&
        GetStockPetEntry(2200416) == 2200416, "stock and unrelated entries are left alone");
    return failures ? 1 : 0;
}
"""


def check(value, name):
    print(f"{'PASS' if value else 'FAIL'}: {name}")
    return value


def reborn_summons(dbc):
    data = (dbc / "Spell.dbc").read_bytes()
    count, fields, size, _ = struct.unpack_from("<4I", data, 4)
    wanted = {}
    for row in range(count):
        record = struct.unpack_from("<%dI" % fields, data, 20 + row * size)
        if OFFSET <= record[0] < 2 * OFFSET:
            for effect, misc in zip(record[EFFECT:EFFECT + 3], record[MISC:MISC + 3]):
                if effect in SUMMON_EFFECTS and OFFSET < misc < 2 * OFFSET:
                    wanted.setdefault(misc, record[0])
    return wanted


def inserted(text, table):
    match = re.search(r"INSERT INTO `%s` \(([^)]*)\) VALUES\n(.*?)(?: ON DUPLICATE KEY UPDATE [^;]*)?;" % table,
                      text, re.S)
    if not match:
        return [], []
    columns = [name.strip(" `") for name in match[1].split(",")]
    rows = [re.findall(r"'(?:\\.|[^'])*'|NULL|[^,\s]+", line.strip()[1:-2 if line.endswith("),") else -1])
            for line in match[2].splitlines()]
    return columns, rows


def check_sql(dbc):
    text = SQL.read_text(encoding="utf-8")
    wanted = reborn_summons(dbc)
    columns, templates = inserted(text, "creature_template")
    created = {int(row[0]): dict(zip(columns, row)) for row in templates}
    ok = check(len(wanted) > 100 and set(wanted) - set(created) <= UNSOURCED | ALREADY_PRESENT,
               "every Reborn summon with a stock creature is created, Summon Imp's 1100416 among them")
    ok &= check(created.get(IMP, {}).get("family") == "'23'" and created.get(VOIDWALKER, {}).get("family") == "'16'",
                "the Reborn Imp and Voidwalker keep their demon families")
    _, models = inserted(text, "creature_template_model")
    _, stats = inserted(text, "pet_levelstats")
    name_columns, names = inserted(text, "pet_name_generation")
    ok &= check(any(row[0] == str(IMP) for row in models) and any(row[0] == str(WATER_ELEMENTAL) for row in models),
                "the Reborn Imp and Water Elemental have models")
    ok &= check(sum(row[0] == str(IMP) for row in stats) == 80, "the Reborn Imp has pet stats for all 80 levels")
    ok &= check(any(dict(zip(name_columns, row)).get("entry") == str(IMP) for row in names),
                "the Reborn Imp is given a demon name")
    return ok


def check_core():
    compiler = shutil.which(os.environ.get("CXX", "cl.exe" if os.name == "nt" else "c++"))
    assert compiler, "Enable a C++20 compiler (VS Developer PowerShell on Windows)."
    with tempfile.TemporaryDirectory(prefix="coa-reborn-summons-") as directory:
        out = Path(directory)
        (out / "Define.h").write_text(STUBS["Define.h"], encoding="utf-8")
        (out / "Optional.h").write_text("#pragma once\n#include <optional>\n"
                                        "template <class T> using Optional = std::optional<T>;\n", encoding="utf-8")
        (out / "main.cpp").write_text(MAIN, encoding="utf-8")
        includes = [out, ROOT / "src/server/game/Entities/Pet"]
        executable = out / ("summons.exe" if os.name == "nt" else "summons")
        if Path(compiler).stem.lower() == "cl":
            flags = ["/nologo", "/std:c++20", "/EHsc", *["/I" + str(p) for p in includes], str(out / "main.cpp"),
                     "/Fe" + str(executable)]
        else:
            flags = ["-std=c++20", *["-I" + str(p) for p in includes], str(out / "main.cpp"), "-o", str(executable)]
        build = subprocess.run([compiler, *flags], cwd=out, capture_output=True, text=True, errors="replace")
        if build.returncode:
            raise SystemExit("Reborn summons harness did not compile:\n" + build.stdout + build.stderr)
        return subprocess.run([str(executable)], text=True).returncode == 0


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    dbc = (args.dbc_dir or dbc_dir()).resolve()
    sql_ok = SQL.is_file() and check_sql(dbc)
    if not SQL.is_file():
        check(False, "the Warcraft Reborn summons update exists")
    raise SystemExit(0 if check_core() and sql_ok else 1)


if __name__ == "__main__":
    main()
