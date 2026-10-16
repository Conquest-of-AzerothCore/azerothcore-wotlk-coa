CLI_DESCRIPTION = """Check that Wardrobe incarnations change shapeshift forms and summoned demons for every class the
client offers them to."""

import argparse
from pathlib import Path
import runpy
import struct
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402

method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
TYPE, KIND, FIRST, SECOND, CLASS_MASK = 1, 19, 20, 21, 23
CATEGORY, DISPLAY, WEAPON = (5, 6, 7), 8, 9
FORM, CREATURE = 1, 2
CLASS_HERO = 10
SHADOWHOUND = 68
EXPECTED = {
    17: (FORM, 5), 18: (FORM, 1), 19: (FORM, 3), 20: (FORM, 4), 21: (FORM, 29), 22: (FORM, 31), 23: (FORM, 2),
    24: (FORM, 16), 31: (FORM, 22), 25: (CREATURE, 416), 26: (CREATURE, 1860), 27: (CREATURE, 1863),
    28: (CREATURE, 417), 29: (CREATURE, 17252),
}


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


def check(ok, text_, problems=()):
    print(f"{'PASS' if ok else 'FAIL'}: {text_}")
    for line in problems:
        print("  ", line)
    return ok


def check_client(directory):
    categories, data, base = read_dbc(directory / "AppearanceCategories.dbc")
    appearances = read_dbc(directory / "Appearances.dbc")[0]
    displays = read_dbc(directory / "CreatureDisplayInfo.dbc")[0]
    incarnations = {category: row for category, row in categories.items() if category != SHADOWHOUND and
                    text(data, base, row[TYPE]) == "APPEARANCE_TYPE_INCARNATION" and row[KIND] in (FORM, CREATURE) and
                    (row[CLASS_MASK] or row[CLASS_MASK + 1])}
    problems = [f"category {category} is {(row[KIND], row[FIRST])}, not {EXPECTED.get(category)}"
                for category, row in incarnations.items() if EXPECTED.get(category) != (row[KIND], row[FIRST])]
    problems += [f"category {category} is not an incarnation" for category in EXPECTED if category not in incarnations]
    problems += [f"category {category} is not offered to Hero" for category, row in incarnations.items()
                 if not row[CLASS_MASK] & (1 << (CLASS_HERO - 1))]
    rows = [row for row in appearances.values() if any(row[index] in incarnations for index in CATEGORY)]
    shown = sum(1 for row in rows if row[DISPLAY] in displays)
    if shown < len(rows) - 2:
        problems.append(f"only {shown} of {len(rows)} incarnation appearances carry a creature display in field 8")
    weapons = sum(1 for row in rows if 29 in row[5:8] and row[WEAPON])
    if not weapons:
        problems.append("no Summoned Felguard appearance carries a weapon in field 9")
    demon = categories.get(34)
    if demon is None or text(data, base, demon[TYPE]) != "APPEARANCE_TYPE_COSMETIC_PET":
        problems.append("Summoned Demon (34) is no longer a cosmetic pet category")
    return check(not problems, f"the client offers {len(incarnations)} incarnation categories to Hero, with {shown} of "
                 f"{len(rows)} appearances carrying a creature display and {weapons} a Felguard weapon", problems)


def check_wiring():
    compat = source("src/server/coa/AscensionCompat.cpp")
    unit = body(source("src/server/game/Entities/Unit/Unit.cpp"),
                "uint32 Unit::GetModelForForm(ShapeshiftForm form, uint32 spellId)")
    problems = [] if "OnPlayerGetShapeshiftModel" in unit else ["GetModelForForm does not ask for an incarnation model"]
    problems += [] if "AppearanceCategories.dbc" in compat else ["the incarnation categories are not read from the client"]
    for signature in ("uint32 GetIncarnationFormDisplay(Player* player, ShapeshiftForm form)",
                      "void RefreshIncarnationGuardian(Player* player, Guardian* guardian)",
                      "AppearanceInfo const* GetActiveIncarnation(Player* player, uint32 category)"):
        code = body(compat, signature)
        if not code:
            problems.append(f"missing {signature}")
        elif "getClass() ==" in code or "getClass() !=" in code or "CLASS_" in code:
            problems.append(f"{signature.split('(')[0]} gates on a class instead of the category's class mask")
    apply = body(compat, "void HandleApplyAppearances(Player *player, WorldPacket &packet)")
    problems += [] if "RefreshIncarnations(player);" in apply else ["applying appearances does not refresh incarnations"]
    for hook in ("PLAYERHOOK_ON_GET_SHAPESHIFT_MODEL", "PLAYERHOOK_ON_AFTER_GUARDIAN_INIT_STATS_FOR_LEVEL"):
        problems += [] if hook in compat else [f"the compat player script does not enable {hook}"]
    return check(not problems, "shapeshift forms and summoned demons take the selected incarnation, gated by the "
                 "category's class mask", problems)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--dbc-dir", type=Path)
    args = parser.parse_args()
    directory = (args.dbc_dir or dbc_dir()).resolve()
    results = [check_client(directory), check_wiring()]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
