CLI_DESCRIPTION = """Exercise the real Vampiric Pools exit callback and its native leech data."""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
CASES = r'''
int main()
{
    Player player;
    player.cls = CLASS_SON_OF_ARUGAL;
    bloodmage_talent_events events;
    AuraApplication removed;
    removed.aura.id = 806310;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.empty());
    player.auras.insert(504088);
    for (auto mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_ENEMY_SPELL})
    {
        player.casts.clear();
        events.OnAuraRemove(&player, &removed, mode);
        assert(player.casts.size() == 1 && std::get<0>(player.casts[0]) == &player &&
            std::get<1>(player.casts[0]) == 806311 && std::get<2>(player.casts[0]));
    }
    player.casts.clear();
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_DEATH);
    removed.aura.caster = 99;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
    removed.aura.caster = player.guid;
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld})
    {
        player.*required = false;
        events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
        player.*required = true;
    }
    player.cls = CLASS_MAGE;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.empty());
    player.cls = CLASS_SON_OF_ARUGAL;
    removed.aura.id = 562572;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.empty());
    player.auras.insert(804851);
    for (auto mode : {AURA_REMOVE_BY_EXPIRE, AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_ENEMY_SPELL})
    {
        player.casts.clear();
        events.OnAuraRemove(&player, &removed, mode);
        assert(player.casts.size() == 1 && std::get<1>(player.casts[0]) == 504264);
    }
    player.casts.clear();
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_DEATH);
    removed.aura.id = 562720; // The ordinary form is not Accursed Form.
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
    removed.aura.id = 562572;
    removed.aura.caster = 99;
    events.OnAuraRemove(&player, &removed, AURA_REMOVE_BY_EXPIRE);
    assert(player.casts.empty());
}
'''


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
                       ("src/server/shared/SharedDefines.h", "SpellCastResult"),
                       ("src/server/shared/SharedDefines.h", "Classes")]:
        enums.append(native.extractor.extract((ROOT / path).read_text(), r"enum " + name + r"\b") + ";")
    code = (Path(__file__).parent.parent / "primalist_talents/harness.cpp").read_text().split("// ACTUAL_SOURCE")[0]
    code = code.replace("// NATIVE_ENUMS", "\n".join(enums))
    code = code.replace("constexpr uint32 CLASS_WILDWALKER = 31, ", "constexpr uint32 ")
    source = (ROOT / "src/server/coa/AscensionBloodmageTalents.cpp").read_text()
    code += native.extractor.extract(source, r"enum BloodmageTalentSpells\b") + ";\n"
    code += native.extractor.extract(source, r"class bloodmage_talent_events\b") + ";\n" + CASES
    with tempfile.TemporaryDirectory(prefix="coa-bloodmage-passives-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "bloodmage-passives")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
               "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT)")
    db.execute("INSERT INTO spell_bonus_data VALUES (42, 1, 2, 3, 4, 'unrelated')")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_04_bloodmage_talents.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT direct_bonus, dot_bonus, ap_bonus FROM spell_bonus_data WHERE entry=806311").fetchone() == (1, 0, 0)
    assert db.execute("SELECT dot_bonus FROM spell_bonus_data WHERE entry=42").fetchone() == (2,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        for offset in range(20, 20 + count * 936, 936):
            if struct.unpack_from("<I", raw, offset)[0] == 806311:
                row = struct.unpack_from("<234I", raw, offset)
                assert row[71:74] == (9, 0, 0) and row[208] == 26
                assert row[86] == 22 and row[89] == 15 and row[213] == 1
                break
        else:
            raise AssertionError("Missing native Vampiric Pools helper")
    print("PASS: Liquify expiry/cancellation, owned talent, death/logout exclusions and native leech coefficient")


if __name__ == "__main__":
    main()
