CLI_DESCRIPTION = """Exercise Ripple lifecycle, expiry trigger, channel shields and saved stagger accounting."""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("ripple_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    enums = []
    for path, names in [
        ("src/server/shared/SharedDefines.h", ["Classes", "SpellSchools", "SpellSchoolMask", "SpellEffects",
                                             "SpellEffIndex", "Targets"]),
        ("src/server/game/Spells/Auras/SpellAuraDefines.h", ["AuraType", "AuraEffectHandleModes", "AuraRemoveMode"]),
        ("src/server/game/Entities/Unit/Unit.h", ["DamageEffectType"]),
        ("src/server/game/Spells/SpellInfo.h", ["SpellCustomAttributes"]),
    ]:
        source = (ROOT / path).read_text()
        enums.extend(native.extractor.extract(source, r"enum " + name + r"\b") + ";" for name in names)
    code = HERE.joinpath("harness.cpp").read_text().replace("// NATIVE_ENUMS", "\n".join(enums))
    source = (ROOT / "src/server/coa/AscensionChronomancerRipple.cpp").read_text()
    code += re.sub(r'^#include.*\n', '', source, flags=re.M).replace(
        ": public AuraScript\n{", ": public AuraScript\n{\npublic:")
    code += HERE.joinpath("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-chronomancer-ripple-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "chronomancer-ripple")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
                     "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT);"
                     "CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_15_chronomancer_ripple.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT entry,direct_bonus FROM spell_bonus_data ORDER BY entry").fetchall() == [
        (503826, 0.25), (560385, 0.125), (560387, 0.385)]
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])}
        assert rows[806296][95] == 147
        assert rows[560384][98] == rows[560388][98] == 500
        assert rows[560396][71] == 65 and rows[560396][92] == 23
        assert rows[525050][71] == 64 and rows[525050][116] == 503826
        assert all(rows[i][40] == 28 for i in [806296, 560384, 560388, 560394, 560396, 806733])
    print("PASS: talent-only Clasp expiry, four Aeons, channel cleanup, absorb eligibility and conserved saved debt")


if __name__ == "__main__":
    main()
