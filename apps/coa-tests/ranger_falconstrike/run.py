CLI_DESCRIPTION = """Exercise Falconstrike's actual temporary acquisition with native replacement methods."""
import argparse
import importlib.util
from pathlib import Path
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]


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
    native = load("falcon_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    base = load("flower_fixture", Path(__file__).parent.parent / "ranger_flowers/run.py")
    code = base.make_harness(native, ROOT / "src/server/coa/AscensionRangerFalconstrike.cpp", "ScriptedAI")
    player = (ROOT / "src/server/game/Entities/Player/Player.cpp").read_text()
    code = code.replace("// NATIVE_REPLACEMENTS", "\n".join(native.extractor.extract(player, pattern) for pattern in [
        r"void Player::SetTemporarySpellReplacement\(", r"uint32 Player::GetTemporarySpellReplacement\("]))
    code = code.replace("int32 duration = 20000;", "int32 duration = 20000;\n    uint32 SpellLevel = 0;")
    code = code.replace("uint32 GetLevel() const { return 40; }", "uint32 level = 10; uint32 GetLevel() const { return level; }")
    code = code.replace("uint32 stacks = 1;", """uint32 stacks = 1;
        int32 duration = 15000;
        int32 GetDuration() const { return duration; }
        void SetDuration(int32 value) { duration = value; }""")
    code = code.replace("casts.push_back(id);", """casts.push_back(id);
        if (id == 573248)
        {
            if (HasAura(id, guid)) auras[id].stacks = std::min(5u, auras[id].stacks + 1);
            else auras[id] = {id, guid};
            auras[id].info.StackAmount = 5;
            auras[id].duration = 15000;
        }
        if (id == 573338)
        {
            auras[id] = {id, guid};
            auras[id].duration = 60000;
        }""", 1)
    code += "\n" + (ROOT / "src/server/coa/AscensionCustomResourceData.h").read_text()
    resource = (ROOT / "src/server/coa/AscensionCompat.cpp").read_text()
    code += native.extractor.extract(resource, r"static bool MatchesGainRule\(")
    code += Path(__file__).with_name("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-falconstrike-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "ranger-falconstrike")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);"
                     "INSERT INTO spell_script_names VALUES (806345, 'spell_ascension_ranger_highlander');")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_12_falconstrike.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (9,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])}
        assert rows[573248][49] == 5 and rows[573248][40] == 8 and rows[573338][40] == 3
        for sid in [500074, *range(572727, 572733)]:
            assert rows[sid][208:212] == (27, 0, 1, 0)
        for sid, level in zip([806345, *range(806437, 806444)], [11, 18, 25, 32, 39, 46, 53, 60]):
            assert rows[sid][208:212] == (27, 0, 4194304, 0) and rows[sid][39] == level
    print("PASS: fourth-shot/horn readiness, native replacement, ranks, cleanup, cast guard and resource amounts")


if __name__ == "__main__":
    main()
