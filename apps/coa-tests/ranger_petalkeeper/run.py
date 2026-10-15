CLI_DESCRIPTION = """Check actual Petalkeeper callbacks, independent red flowers and Red Dream healing."""
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
    native = load("petal_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    base = load("flower_fixture", Path(__file__).parent.parent / "ranger_flowers/run.py")
    code = base.make_harness(native, ROOT / "src/server/coa/AscensionRangerPetalkeeper.cpp",
                             "npc_ascension_ranger_red_flower")
    code = "#include <limits>\n#include <set>\n" + code
    code = code.replace("using uint8 =", "using uint64 = std::uint64_t;\nusing uint8 =")
    damage_type = native.extractor.extract((ROOT / "src/server/game/Entities/Unit/Unit.h").read_text(), r"enum DamageEffectType\b")
    code = code.replace("struct DamageInfo { uint32 amount = 1; uint32 GetDamage() { return amount; } };", damage_type + ";" + """
        struct DamageInfo
        {
            uint32 amount = 1;
            DamageEffectType type = SPELL_DIRECT_DAMAGE;
            uint32 GetDamage() const { return amount; }
            DamageEffectType GetDamageType() const { return type; }
        };""")
    code = code.replace("struct AuraEffect { };", "struct AuraEffect { int32 amount = 10; int32 GetAmount() const { return amount; } };")
    code = code.replace("struct AuraScript\n{", """struct AuraScript
    {
        virtual bool Validate(SpellInfo const*) { return true; }
        bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }""")
    code = code.replace("struct Unit\n{", "constexpr int SPELLVALUE_BASE_POINT0 = 0;\nstruct Unit\n{")
    code = code.replace("std::vector<uint32> casts;", """std::vector<uint32> casts;
        std::vector<std::pair<uint32, int32>> heals;
        void CastCustomSpell(uint32 id, int parameter, int32 value, Unit* target, bool triggered)
        {
            assert(target == this && triggered && parameter == SPELLVALUE_BASE_POINT0);
            heals.emplace_back(id, value);
        }""")
    code = code.replace("casts.push_back(id);", """casts.push_back(id);
        if (id == 521220)
        {
            bool existing = target->HasAura(id, guid);
            auto& aura = target->auras[id];
            aura.id = id;
            aura.caster = guid;
            aura.info.StackAmount = 10;
            aura.stacks = existing ? std::min(10u, aura.stacks + 1) : 1;
        }""", 1)
    code += Path(__file__).with_name("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-petalkeeper-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "ranger-petalkeeper")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT, faction INT,
            unit_class INT, type INT, ScriptName TEXT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale FLOAT, Probability FLOAT);
        CREATE TABLE creature_model_info (DisplayID INT, BoundingRadius FLOAT, CombatReach FLOAT, Gender INT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        CREATE TABLE spell_proc (SpellId INT, ProcFlags INT, SpellTypeMask INT, SpellPhaseMask INT,
            HitMask INT, AttributesMask INT, Chance INT);
        INSERT INTO spell_script_names VALUES (520925, 'unrelated');
    """)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_11_ranger_red_flowers.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT CreatureDisplayID FROM creature_template_model").fetchone() == (137539,)
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (4,)
    assert db.execute("SELECT HitMask FROM spell_proc ORDER BY SpellId").fetchall() == [(2,), (3,)]
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])}
        assert rows[521222][71] == 28 and rows[521222][110] == 454240 and rows[521222][92] == 18 and rows[521222][40] == 9
        assert rows[521220][49] == 10 and rows[521220][86] == 21 and rows[521220][96] == 61
        assert rows[521451][95:97] == (354, 305) and rows[521451][80] + rows[521451][74] == 10
        assert rows[521451][81] + rows[521451][75] == 100 and rows[521451][40] == 31
        assert rows[521451][92:94] == (9, 9) and rows[521451][116] == 521643
        assert rows[521643][71] == 10 and rows[521643][6] & 0x20000000 and rows[521643][7] & 0x20000000
        assert rows[806368][211] == 8192 and rows[800086][211] == 1
        tool = load("petal_models", ROOT / "apps/coa-spells/ranger_red_flower.py")
        for table, captured in tool.ROWS.items():
            raw = (args.spell_dbc.parent / (table + ".dbc")).read_bytes()
            output = tool.transform(raw, table)
            assert tool.transform(output, table) == output
            old, strings = tool.dbc.read(raw, len(captured[0]))
            new, new_strings = tool.dbc.read(output, len(captured[0]))
            assert new[:len(old)] == old and new_strings[:len(strings)] == strings
    print("PASS: Petalkeeper ownership/stacks, one-shot horn burst, direct-damage healing, SQL and captured model")


if __name__ == "__main__":
    main()
