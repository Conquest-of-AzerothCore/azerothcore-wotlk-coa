CLI_DESCRIPTION = """Check actual Air Elemental ownership/procs and native Invigoration stacking."""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    parser.add_argument("--before", help="Use this Git revision's pet script as a regression negative control")
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("air_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    code = Path(__file__).with_name("harness.cpp").read_text()
    pet_defines = (ROOT / "src/server/game/Entities/Pet/PetDefines.h").read_text()
    enums = [re.search(r"constexpr auto MAX_PET_STABLES = \d+;", pet_defines)[0]]
    for path, names in [
        ("src/server/shared/SharedDefines.h", ["Classes", "SpellAttr1"]),
        ("src/server/game/Entities/Pet/PetDefines.h", ["PetType", "PetSaveMode"]),
        ("src/server/game/Spells/Auras/SpellAuraDefines.h", ["AuraRemoveMode"]),
    ]:
        source = (ROOT / path).read_text()
        enums.extend(native.extractor.extract(source, r"enum " + name + r"\b") + ";" for name in names)
    code = code.replace("// NATIVE_ENUMS", "\n".join(enums))
    stack = native.extractor.extract((ROOT / "src/server/game/Spells/Auras/SpellAuras.cpp").read_text(), r"bool Aura::ModStackAmount\(")
    code = code.replace("// NATIVE_STACK", stack)
    source_path = "src/server/coa/AscensionStormbringerPet.cpp"
    source = (git_source(["git", "show", f"{args.before}:{source_path}"], cwd=ROOT, text=True)
              if args.before else (ROOT / source_path).read_text())
    source = re.sub(r"^#include.*\n", "", source, flags=re.M)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    source = source.replace(": public AuraScript\n{", ": public AuraScript\n{\npublic:")
    code = code.replace("// ACTUAL_SOURCE", source)
    with tempfile.TemporaryDirectory(prefix="coa-air-elemental-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "air-elemental")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT, faction INT,
            unit_class INT, type INT, family INT);
        CREATE TABLE creature_template_spell (CreatureID INT, `Index` INT, Spell INT, VerifiedBuild INT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale FLOAT, Probability FLOAT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        CREATE TABLE spell_proc (SpellId INT, ProcFlags INT, SpellTypeMask INT, SpellPhaseMask INT,
            HitMask INT, AttributesMask INT, Chance INT);
        INSERT INTO spell_script_names VALUES (806020, 'unrelated');
    """)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_09_air_elemental.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID=500941").fetchone() == (8714,)
    assert db.execute("SELECT family FROM creature_template WHERE entry=500941").fetchone() == (0,)
    assert db.execute("SELECT `Index`, Spell FROM creature_template_spell WHERE CreatureID=500941 ORDER BY `Index`").fetchall() == [(0, 806016), (1, 300836), (2, 804022)]
    assert db.execute("SELECT * FROM spell_proc").fetchone() == (806020, 332116, 1, 2, 3, 2, 100)
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (3,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        wanted = {804019, 806010, 806020, 500348, 680918, 806016, 300836, 804022, 712431, 712488, 500019, 804036, 707543, 807465, 807555, 807464}
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936]) if r[0] in wanted}
        assert rows[804019][71] == 56 and rows[804019][110] == 500941
        assert rows[806010][71:74] == (6, 6, 140) and rows[806010][86:89] == (5, 5, 5)
        assert rows[806010][118] == 806020 and rows[806020][95] == 42 and rows[806020][116] == 500348
        assert rows[500348][72] == 64 and rows[500348][117] == 680918
        assert rows[680918][49] == 10 and rows[680918][95] == 79 and rows[680918][80:81] == (2,)
        assert rows[806016][71] == 2 and rows[806016][104] == 2
        assert rows[300836][71:73] == (2, 183) and rows[300836][117] == 300838
        assert rows[804022][71] == 65 and rows[804022][95] == 216
        assert rows[712431][208] == rows[712488][208] == rows[500019][208] == 22
        assert rows[712488][35] == 15 and rows[712488][117] == 500019
        assert rows[500019][95] == 108 and rows[500019][110] == 0
        assert rows[500019][80] + rows[500019][74] == 200
        assert rows[500019][123] & rows[804036][210] == 131072
        assert rows[707543][71] == 140 and rows[707543][86] == 5 and rows[707543][116] == 807465
        assert rows[807465][86] == 1 and rows[807465][34] == 0
        assert rows[807555][208] == 22 and rows[807555][95] == 3 and rows[807555][98] == 3000
        assert rows[807555][80] + rows[807555][74] == 59 and rows[807555][40] == 86
        assert rows[807464][95:97] == (22, 87) and rows[807464][110:112] == (126, 126)
        raw = (args.spell_dbc.parent / "CreatureDisplayInfo.dbc").read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        displays = {r[0]: r for r in struct.iter_unpack("<16I", raw[20:20 + count * 64])}
        assert displays[8714][1] == 591
    print("PASS: Air Elemental native pet type, load-safe passives, damage procs, native stack duration and SQL")


if __name__ == "__main__":
    main()
