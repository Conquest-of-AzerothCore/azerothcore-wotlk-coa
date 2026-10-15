CLI_DESCRIPTION = """Exercise Pooled Vitality with actual payment, spell-modifier and module code."""
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
    spec = importlib.util.spec_from_file_location("vitality_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    enums = []
    for path, names in [
        ("src/server/shared/SharedDefines.h", ["Classes", "Powers", "Stats", "SpellCastResult", "SpellMissInfo",
                                             "SpellEffects", "SpellEffIndex"]),
        ("src/server/game/Spells/SpellDefines.h", ["SpellModOp"]),
        ("src/server/game/Entities/Player/Player.h", ["SpellModType"]),
        ("src/server/game/Entities/Unit/Unit.h", ["DamageEffectType"]),
    ]:
        source = (ROOT / path).read_text()
        enums.extend(native.extractor.extract(source, r"enum " + name + r"\b") + ";" for name in names)
    code = HERE.joinpath("harness.cpp").read_text().replace("// NATIVE_ENUMS", "\n".join(enums))
    code = re.search(r"^#define MAX_SPELLMOD .*", (ROOT / "src/server/game/Spells/SpellDefines.h").read_text(), re.M)[0] + "\n" + code
    header = (ROOT / "src/server/game/Spells/AscensionPooledVitality.h").read_text()
    code += re.sub(r'^#include.*\n', '', header, flags=re.M)
    player = (ROOT / "src/server/game/Entities/Player/Player.cpp").read_text()
    code += "\n#pragma warning(push)\n#pragma warning(disable: 4244)\ntemplate<class T>\n"
    code += native.extractor.extract(player, r"(?m)^void Player::ApplySpellMod\(")
    code += "\n#pragma warning(pop)\n"
    spell = (ROOT / "src/server/game/Spells/Spell.cpp").read_text()
    code += native.extractor.extract(spell, r"void Spell::TakePower\(")
    module = (ROOT / "src/server/coa/AscensionBloodmageVitality.cpp").read_text()
    code += re.sub(r'^#include.*\n', '', module, flags=re.M).replace(
        ": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    code += HERE.joinpath("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-pooled-vitality-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "pooled-vitality")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
                     "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT);"
                     "CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);"
                     "INSERT INTO spell_script_names VALUES (42, 'unrelated');")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_13_pooled_vitality.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT direct_bonus, ap_bonus FROM spell_bonus_data").fetchone() == (0.25, 0)
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (18,)
    prepare = native.extractor.extract(spell, r"SpellCastResult Spell::prepare\(")
    assert prepare.index("CanPrepare(") < prepare.index("CalcPowerCost(") < prepare.index("CalcCastTime(")
    cast = native.extractor.extract(spell, r"void Spell::_cast\(")
    assert cast.index("CheckCast(false)") < cast.index("SelectSpellTargets()") < cast.index("TakePower()")
    assert cast.index("TakePower()") < cast.index("OnSpellBeforeEffects(") < cast.index("HandleLaunchPhase()")
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])}
        assert rows[680687][49] == 10
        assert rows[681025][71] == 10 and rows[681025][86] == 22 and rows[681025][89] == 30
        assert rows[681025][212] == 10 and rows[681025][92] == 10
        assert rows[681032][6] & 536870912 and rows[681032][10] & 536870912
        for sid, in db.execute("SELECT spell_id FROM spell_script_names WHERE spell_id != 42"):
            assert rows[sid][208] == 26 and rows[sid][41] == 1
    print("PASS: actual health payment, empowerment timing/modifiers, cancellation, ownership, spend heal and hit bonuses")


if __name__ == "__main__":
    main()
