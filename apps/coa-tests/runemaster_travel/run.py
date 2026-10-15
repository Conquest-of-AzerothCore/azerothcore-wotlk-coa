CLI_DESCRIPTION = """Execute actual travel callbacks with bounded maps, movement and spell ownership.

Uses native enums and the native temporary replacement/packet functions. It does
not simulate collision geometry, movement splines, client acknowledgements or a
full heal/damage calculation. Native persistent/temporary ownership is separately
exercised by tests/taught_abilities. All generated DBC bytes stay in memory.
"""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    native = load("travel_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    enums = []
    for path, names in [
        ("src/server/shared/SharedDefines.h", ["Classes", "SpellEffects", "Targets", "SpellCastResult"]),
        ("src/server/game/Spells/Auras/SpellAuraDefines.h", ["AuraRemoveMode"]),
        ("src/server/game/Movement/MotionMaster.h", ["ForcedMovement"]),
        ("src/server/game/Entities/Object/Object.h", ["TempSummonType"]),
    ]:
        source = (ROOT / path).read_text()
        enums.extend(native.extractor.extract(source, r"enum " + name + r"\b") + ";" for name in names)
    source = (ROOT / "src/server/coa/AscensionRunemasterTravel.cpp").read_text()
    source = re.sub(r"^#include.*\n", "", source, flags=re.M)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    player = (ROOT / "src/server/game/Entities/Player/Player.cpp").read_text()
    replacements = "\n".join(native.extractor.extract(player, pattern) for pattern in [
        r"void Player::SetTemporarySpellReplacement\(", r"uint32 Player::GetTemporarySpellReplacement\("])
    code = (HERE / "harness.cpp").read_text().replace("// NATIVE_ENUMS", "\n".join(enums))
    code = code.replace("// NATIVE_REPLACEMENTS", replacements).replace("// ACTUAL_SOURCE", source)
    with tempfile.TemporaryDirectory(prefix="coa-runemaster-travel-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "runemaster-travel")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT,
            faction INT, unit_class INT, type INT, ScriptName TEXT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale FLOAT, Probability FLOAT);
        CREATE TABLE creature_model_info (DisplayID INT, BoundingRadius FLOAT, CombatReach FLOAT, Gender INT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        CREATE TABLE spell_bonus_data (entry INT, direct_bonus FLOAT, dot_bonus FLOAT, ap_bonus FLOAT,
            ap_dot_bonus FLOAT, comments TEXT);
        INSERT INTO spell_script_names VALUES (500270, 'unrelated');
    """)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_06_runemaster_travel.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT CreatureID, CreatureDisplayID FROM creature_template_model ORDER BY CreatureID").fetchall() == [
        (50063, 460733), (51335, 131041)]
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (5,)
    assert db.execute("SELECT direct_bonus, ap_bonus FROM spell_bonus_data ORDER BY entry").fetchall() == [(0, 1.5), (.44, .2)]
    tool = load("travel_dbc", ROOT / "apps/coa-spells/runemaster_travel.py")
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        rows, strings = tool.read(raw, 234)
        updated = tool.transform(raw, "Spell")
        assert tool.transform(updated, "Spell") == updated
        changed, changed_strings = tool.read(updated, 234)
        assert changed_strings[:len(strings)] == strings
        for old, new in zip(rows, changed):
            if old[0] == 500272:
                assert {i for i in range(234) if old[i] != new[i]} <= {153, 170}
                assert new[153] == 0
                start = new[170]
                assert changed_strings[start:changed_strings.index(0, start)].decode() == tool.ECHO_RETURN_DESCRIPTION
            else:
                assert new == old
        wanted = {r[0]: r for r in rows if r[0] in {500270, 500272, 500287, 500495, 500587, 500588, 500606}}
        assert wanted[500270][71:74] == (28, 6, 6) and wanted[500270][110:114:3] == (50063, 61)
        assert wanted[500270][40] == wanted[500606][40] == 18
        assert wanted[500287][71] == 3 and wanted[500287][29] == 30000
        assert wanted[500606][110:114:3] == (51335, 61)
        assert wanted[500272][71] == 10 and wanted[500495][71] == 2
        assert wanted[500587][71:74] == (77, 164, 3)
        assert wanted[500588][95] == 31 and wanted[500588][80] + wanted[500588][74] == 200
        start = wanted[500287][187]
        assert b"30 yds" in strings[start:strings.index(0, start)]
        for table, captured in tool.ROWS.items():
            source = (args.spell_dbc.parent / (table + ".dbc")).read_bytes()
            output = tool.transform(source, table)
            assert tool.transform(output, table) == output
            width = len(captured[0])
            old, old_strings = tool.read(source, width)
            new, new_strings = tool.read(output, width)
            assert new[:len(old)] == old and new_strings[:len(old_strings)] == old_strings
            assert {r[0] for r in captured} <= {r[0] for r in new}
            corrupt = bytearray(output)
            index = next(i for i, row in enumerate(new) if row[0] == captured[0][0])
            struct.pack_into("<I", corrupt, 20 + index * width * 4 + 4, 999)
            try:
                tool.transform(corrupt, table)
                raise AssertionError("Conflicting model was accepted")
            except ValueError:
                pass
    print("PASS: owned markers, native buttons, return/expiry, moving destination, teleport acknowledgement, cleanup and data")


if __name__ == "__main__":
    main()
