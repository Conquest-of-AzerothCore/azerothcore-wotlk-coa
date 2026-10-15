CLI_DESCRIPTION = """Exercise the actual Zephyr summon, lifetime, pull guards and captured data."""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
TESTS = Path(__file__).resolve().parent.parent
SUPPORT = r'''
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<int>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
constexpr int GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1;
'''
CASES = r'''
int main()
{
    Map map, otherMap;
    Player player, enemy;
    player.guid = {1};
    enemy.guid = {2};
    player.map = enemy.map = &map;
    player.cls = CLASS_STORMBRINGER;
    player.spells[704201] = 1;
    spell_ascension_raging_zephyr summon;
    summon.caster = &player;
    summon.info.Id = 704201;
    summon.info.duration = 12000;
    assert(summon.Load());
    summon.Summon(0);
    assert(player.creatures.empty()); // No destination, no arbitrary summon.
    WorldLocation destination{12, 23, 34, 1};
    summon.fixtureDestination = &destination;
    summon.Summon(0);
    auto zephyr = player.creatures.back().get();
    assert(zephyr->entry == 4078281 && zephyr->createdBy == 704201 && zephyr->position == destination);
    assert(zephyr->motion.idle && zephyr->react == REACT_PASSIVE && zephyr->duration == 12000);
    assert(zephyr->faction == player.GetFaction() && zephyr->ownerGuid == player.guid);
    assert(zephyr->casts == std::vector<uint32>{725390});
    auto aura = zephyr->GetAura(725390, zephyr->guid);
    assert(aura && aura->duration == 12000 && aura->maximum == 12000);
    // Multiple charges can overlap. A new tornado does not replace or refresh an older one.
    player.durationMod = 4000;
    summon.Summon(0);
    auto next = player.creatures.back().get();
    assert(next != zephyr && !zephyr->removed && next->duration == 16000);
    assert(next->GetAura(725390, next->guid)->duration == 16000 && aura->duration == 12000);
    player.durationMod = 0;
    player.failSummon = true;
    summon.Summon(0);
    assert(player.creatures.size() == 2 && !zephyr->removed && !next->removed);
    player.failSummon = false;
    spell_ascension_zephyr_pull pull;
    pull.caster = zephyr;
    pull.fixtureTarget = &enemy;
    for (int pulse = 0; pulse < 3; ++pulse)
    {
        pull.CheckTarget(0);
        assert(!pull.prevented); // Every native pulse reaches the native movement effect.
    }
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld, &Unit::samePhase, &Unit::hostile})
    {
        enemy.*required = false;
        pull.CheckTarget(0);
        assert(pull.prevented);
        pull.prevented = false;
        enemy.*required = true;
    }
    for (bool Player::* blocked : {&Player::teleporting, &Player::flight, &Player::vehicle, &Player::transport})
    {
        enemy.*blocked = true;
        pull.CheckTarget(0);
        assert(pull.prevented);
        pull.prevented = false;
        enemy.*blocked = false;
    }
    enemy.map = &otherMap;
    pull.CheckTarget(0);
    assert(pull.prevented);
    pull.prevented = false;
    enemy.map = &map;
    zephyr->ownerGuid = {99};
    pull.CheckTarget(0);
    assert(pull.prevented);
    pull.prevented = false;
    zephyr->ownerGuid = player.guid;
    player.spells.erase(704201);
    pull.CheckTarget(0);
    assert(pull.prevented); // Parent loss blocks a pulse before the next AI cleanup event.
    zephyr->ai->UpdateAI(500);
    next->ai->UpdateAI(500);
    assert(zephyr->removed && next->removed);
    player.spells[704201] = 1;
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld, &Unit::samePhase})
    {
        summon.Summon(0);
        next = player.creatures.back().get();
        player.*required = false;
        next->ai->UpdateAI(500);
        assert(next->removed);
        player.*required = true;
    }
    summon.Summon(0);
    next = player.creatures.back().get();
    player.map = &otherMap;
    next->ai->UpdateAI(500);
    assert(next->removed);
    player.map = &map;
    player.failPeriodic = true;
    summon.Summon(0);
    assert(player.creatures.back()->removed);
    player.cls = CLASS_MAGE;
    assert(!summon.Load());
    stormbringer_zephyr_metadata metadata;
    for (uint32 id : {704201u, 704210u, 725390u, 1u})
    {
        SpellInfo info;
        info.Id = id;
        info.SpellFamilyName = 22;
        info.Effects[0].Effect = 124;
        info.Effects[1].Effect = 1;
        metadata.OnLoadSpellCustomAttr(&info);
        assert(info.Effects[0].Effect == 124);
        assert(info.Effects[1].Effect == ((id == 704201 || id == 704210) ? 0u : 1u));
        info.SpellFamilyName = 3;
        info.Effects[1].Effect = 1;
        metadata.OnLoadSpellCustomAttr(&info);
        assert(info.Effects[1].Effect == 1);
    }
}
'''


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
    native = load("zephyr_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    shared = (TESTS / "runemaster_travel/harness.cpp").read_text()
    code = shared.split("// ACTUAL_SOURCE")[0]
    enums = []
    for path, names in [
        ("src/server/shared/SharedDefines.h", ["Classes", "SpellEffects", "Targets", "SpellCastResult"]),
        ("src/server/game/Spells/Auras/SpellAuraDefines.h", ["AuraRemoveMode"]),
        ("src/server/game/Movement/MotionMaster.h", ["ForcedMovement"]),
        ("src/server/game/Entities/Object/Object.h", ["TempSummonType"]),
    ]:
        source = (ROOT / path).read_text()
        enums.extend(native.extractor.extract(source, r"enum " + name + r"\b") + ";" for name in names)
    code = code.replace("// NATIVE_ENUMS", "\n".join(enums))
    code = code.replace("struct SpellImplicitTargetInfo", "using WorldLocation = Position;\nstruct SpellImplicitTargetInfo")
    code = code.replace("uint32 id = 0;\n    ObjectGuid caster;", """uint32 id = 0;
        int32 duration = 8000, maximum = 8000;
        void SetDuration(int32 value) { duration = value; }
        void SetMaxDuration(int32 value) { maximum = value; }
        ObjectGuid caster;""")
    code = code.replace("std::map<uint32, Aura> auras;", """std::map<uint32, Aura> auras;
        bool hostile = true, failPeriodic = false;
        virtual Creature* ToCreature() { return nullptr; }
        virtual bool IsInFlight() const { return false; }
        virtual bool GetVehicle() const { return false; }
        virtual bool GetTransport() const { return false; }
        bool IsValidAttackTarget(Unit* target) const { return target->hostile; }
        Aura* GetAura(uint32 id, ObjectGuid caster)
        {
            return HasAura(id, caster) ? &auras.at(id) : nullptr;
        }""")
    code = code.replace("if (id == 500289 || id == 500588)\n            auras[id] = {id, guid};", """if (!failPeriodic)
        {
            auras[id].id = id;
            auras[id].caster = guid;
        }""")
    code = code.replace("uint32 GetEntry() const", "Creature* ToCreature() override { return this; }\n    uint32 GetEntry() const")
    code = code.replace("void ApplySpellMod(uint32, uint32 op, int32&) { assert(op == SPELLMOD_DURATION); }", """int32 durationMod = 0;
        void ApplySpellMod(uint32, uint32 op, int32& duration) { assert(op == SPELLMOD_DURATION); duration += durationMod; }""")
    code = code.replace("virtual bool Validate(SpellInfo const*)", "virtual bool Load() { return true; }\n    virtual bool Validate(SpellInfo const*)")
    code = code.replace("Unit* GetCaster() { return caster; }", """Unit* fixtureTarget = nullptr;
        WorldLocation* fixtureDestination = nullptr;
        WorldLocation const* GetHitDest() { return fixtureDestination; }
        Unit* GetHitUnit() { return fixtureTarget; }
        Unit* GetCaster() { return caster; }""")
    source = (ROOT / "src/server/coa/AscensionStormbringerZephyr.cpp").read_text()
    source = re.sub(r"^#include.*\n", "", source, flags=re.M)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    summon = native.extractor.extract(shared, r"TempSummon\* Player::SummonCreature\(")
    summon = summon.replace("TEMPSUMMON_MANUAL_DESPAWN", "TEMPSUMMON_TIMED_OR_DEAD_DESPAWN")
    summon = summon.replace("npc_ascension_runemaster_marker", "npc_ascension_stormbringer_zephyr")
    summon = summon.replace("marker->owner = this;", "marker->owner = this; marker->failPeriodic = failPeriodic;")
    code += SUPPORT + source + summon + CASES
    with tempfile.TemporaryDirectory(prefix="coa-zephyr-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "raging-zephyr")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT, faction INT,
            unit_class INT, type INT, ScriptName TEXT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale FLOAT, Probability FLOAT);
        CREATE TABLE creature_model_info (DisplayID INT, BoundingRadius FLOAT, CombatReach FLOAT, Gender INT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        INSERT INTO spell_script_names VALUES (704201, 'unrelated');
    """)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_08_raging_zephyr.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT CreatureID, CreatureDisplayID FROM creature_template_model").fetchall() == [(4078281, 407828)]
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (3,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936]) if r[0] in {704201, 725390, 704210}}
        assert rows[704201][71:73] == (28, 27) and rows[704201][110:114:3] == (4078281, 61)
        assert rows[704201][40] == 29 and rows[725390][40] == 31
        assert rows[725390][71:74] == (6, 6, 6) and rows[725390][95:98] == (23, 26, 39)
        assert rows[725390][98] == 4000 and rows[725390][116] == 704210 and rows[725390][112] == 127
        assert rows[704210][71:73] == (124, 1) and rows[704210][86:88] == (22, 1)
        assert rows[704210][89] == 15 and rows[704210][92] == 45 and rows[704210][110] == 180
        tool = load("zephyr_models", ROOT / "apps/coa-spells/raging_zephyr.py")
        for table, captured in tool.ROWS.items():
            raw = (args.spell_dbc.parent / (table + ".dbc")).read_bytes()
            output = tool.transform(raw, table)
            assert tool.transform(output, table) == output
            old, strings = tool.dbc.read(raw, len(captured[0]))
            new, new_strings = tool.dbc.read(output, len(captured[0]))
            assert new[:len(old)] == old and new_strings[:len(strings)] == strings
    print("PASS: Zephyr stationary summons, independent lifetime, pull guards, SQL and captured model data")


if __name__ == "__main__":
    main()
