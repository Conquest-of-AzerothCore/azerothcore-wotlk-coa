CLI_DESCRIPTION = """Execute the Primalist #88 callbacks with bounded world APIs and native enum values."""
import argparse
import importlib.util
from pathlib import Path
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("native_compile",
                                                 args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    enums = []
    for path, name in [("src/server/game/Entities/Unit/UnitDefines.h", "UnitState"),
                       ("src/server/game/Spells/Auras/SpellAuraDefines.h", "AuraRemoveMode"),
                       ("src/server/shared/SharedDefines.h", "SpellCastResult")]:
        enums.append(native.extractor.extract((ROOT / path).read_text(), r"enum " + name + r"\b") + ";")
    full_source = (ROOT / "src/server/coa/AscensionPrimalistTalents.cpp").read_text()
    declarations = [
        (r"enum PrimalistAbilitySpells\b", ";"),
        (r"Player\* Primalist\(", ""),
        (r"class primalist_talent_events\b", ";"),
        (r"class primalist_talent_casts\b", ";"),
        (r"SpellCastResult CheckThroatClamp\(", ""),
        (r"class spell_ascension_throat_clamp\b", ";"),
    ]
    source = "\n".join(native.extractor.extract(full_source, pattern) + suffix
                       for pattern, suffix in declarations)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    code = (HERE / "harness.cpp").read_text().replace("// NATIVE_ENUMS", "\n".join(enums))
    code = code.replace("// ACTUAL_SOURCE", source)
    with tempfile.TemporaryDirectory(prefix="coa-primalist-talents-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "primalist-talents")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT)")
    db.execute("INSERT INTO spell_script_names VALUES (500764, 'unrelated')")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_00_primalist_talents.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (2,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {500764, 500811, 560179, 503716, 500402, 803138, 802885, *range(502769, 502778)}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert rows[500764][71] == 3 and rows[500811][71:73] == (68, 96)
        assert rows[500811][40] == rows[500764][40] == 27
        assert rows[500811][208] == 37 and rows[500811][86:88] == (6, 6)
        assert rows[560179][71:73] == (136, 6) and rows[560179][80] + rows[560179][74] == 30
        assert rows[560179][96] == 87 and rows[560179][111] == 1
        assert rows[503716][95:97] == (138, 47)
        for spell_id in (500402, *range(502769, 502778)):
            assert rows[spell_id][95] == 227 and rows[spell_id][116] == 803138
        assert rows[803138][71:74] == (2, 0, 0) and rows[803138][208] == 37
        assert rows[802885][72] == 30 and rows[802885][111] == 1
        assert rows[802885][81] == 29 and rows[802885][75] == 51
    print("PASS: lethal boundary/cooldown, defense removal, owned Tremor crits, pet command gates and native helpers")


if __name__ == "__main__":
    main()
