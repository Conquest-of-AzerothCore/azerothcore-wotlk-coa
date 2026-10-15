CLI_DESCRIPTION = """Exercise Wind Gate's actual summon, acquisition, target checks and charge metadata."""
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
constexpr int GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1, PLAYERHOOK_ON_LEARN_SPELL = 6;
'''
CASES = r'''
int main()
{
    Map map, otherMap;
    Player player, ally;
    player.guid = {1};
    ally.guid = {2};
    player.map = ally.map = &map;
    player.cls = CLASS_STORMBRINGER;
    manager.spells[504644].Id = 504644;
    stormbringer_gate_lifecycle lifecycle;
    lifecycle.OnPlayerLogin(&player);
    assert(!player.HasActiveSpell(504643));
    player.spells[504401] = 0;
    lifecycle.OnPlayerLearnSpell(&player, 504401);
    assert(player.spells.at(504643) == 1);
    lifecycle.OnPlayerLearnSpell(&player, 504643);
    spell_ascension_wind_gate_evacuate evacuate;
    evacuate.caster = &player;
    evacuate.fixtureTarget = &ally;
    assert(evacuate.CheckPull() != SPELL_CAST_OK);
    spell_ascension_wind_gate place;
    place.caster = &player;
    place.info.Id = 504401;
    place.info.duration = 60000;
    assert(place.Load());
    place.Summon(0);
    assert(!GetWindGate(&player)); // No destination cannot create a gate at an arbitrary position.
    WorldLocation destination{12, 23, 34, 1};
    place.fixtureDestination = &destination;
    place.Summon(0);
    auto gate = GetWindGate(&player);
    assert(gate && gate->GetPosition() == destination && gate->duration == 60000 && gate->motion.idle);
    assert(gate->entry == 617478 && gate->createdBy == 504401 && gate->ownerGuid == player.guid);
    assert(evacuate.CheckPull() == SPELL_CAST_OK);
    evacuate.Pull(0);
    assert(gate->casts == std::vector<uint32>{504644} && gate->lastCastTarget == &ally);
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld, &Unit::samePhase, &Unit::los, &Unit::inRange,
                                  &Unit::raid, &Unit::friendly})
    {
        ally.*required = false;
        assert(evacuate.CheckPull() != SPELL_CAST_OK);
        evacuate.Pull(0);
        ally.*required = true;
    }
    for (bool Player::* blocked : {&Player::teleporting, &Player::flight, &Player::vehicle, &Player::transport})
    {
        ally.*blocked = true;
        assert(evacuate.CheckPull() != SPELL_CAST_OK);
        evacuate.Pull(0);
        ally.*blocked = false;
    }
    assert(gate->casts.size() == 1);
    ally.map = &otherMap;
    assert(evacuate.CheckPull() != SPELL_CAST_OK);
    ally.map = &map;
    player.failSummon = true;
    place.Summon(0);
    assert(GetWindGate(&player) == gate && !gate->removed);
    player.failSummon = false;
    place.Summon(0);
    auto replacement = GetWindGate(&player);
    assert(replacement != gate && gate->removed);
    gate->ai.reset();
    assert(GetWindGate(&player) == replacement);
    replacement->ownerGuid = {99};
    assert(evacuate.CheckPull() != SPELL_CAST_OK);
    RemoveWindGate(&player);
    assert(!replacement->removed); // Never despawn another owner's creature.
    place.Summon(0);
    gate = GetWindGate(&player);
    player.map = &otherMap;
    lifecycle.OnPlayerMapChanged(&player);
    assert(!GateGuid(player.guid) && player.spells.at(504643) == 1);
    gate->ai->UpdateAI(500);
    assert(gate->removed);
    player.map = &map;
    place.Summon(0);
    gate = GetWindGate(&player);
    player.alive = false;
    gate->ai->UpdateAI(500);
    assert(gate->removed && !GateGuid(player.guid));
    player.alive = true;
    place.Summon(0);
    lifecycle.OnPlayerLogout(&player);
    assert(!GateGuid(player.guid) && player.spells.at(504643) == 1);
    player.spells.erase(504401);
    lifecycle.OnPlayerForgotSpell(&player, 504401);
    assert(!player.spells.contains(504643));
    player.spells[504643] = 0;
    lifecycle.OnPlayerForgotSpell(&player, 504401);
    assert(player.spells.at(504643) == 0); // Independent permanent ownership survives.
    player.spells[504643] = -1;
    player.spells[504401] = 0;
    lifecycle.OnPlayerLogin(&player);
    assert(player.spells.at(504643) == -1);
    player.spells.erase(504643);
    player.cls = CLASS_MAGE;
    lifecycle.OnPlayerLearnSpell(&player, 504401);
    assert(!player.spells.contains(504643) && !place.Load());
    stormbringer_gate_metadata metadata;
    SpellInfo info;
    info.SpellFamilyName = 22;
    info.Id = 504643;
    metadata.OnLoadSpellCustomAttr(&info);
    assert(!info.MaxCharges); // The pool comes from the client's SpellCharges.dbc: category 532, 2 charges, 60 s.
    info.MaxCharges = 2;
    info.ChargeRecoveryTime = 60000;
    SpellChargeState pool;
    assert(pool.Consume(info.MaxCharges, info.ChargeRecoveryTime, 100));
    assert(pool.Consume(info.MaxCharges, info.ChargeRecoveryTime, 100));
    assert(!pool.Consume(info.MaxCharges, info.ChargeRecoveryTime, 100));
    pool.Update(info.MaxCharges, 60100);
    assert(pool.Available == 1 && pool.NextRecovery == 120100);
    pool.Update(info.MaxCharges, 120100);
    assert(pool.Available == 2);
    info.Id = 504401;
    info.Effects[0].Effect = SPELL_EFFECT_SUMMON;
    info.Effects[1].Effect = SPELL_EFFECT_PERSISTENT_AREA_AURA;
    metadata.OnLoadSpellCustomAttr(&info);
    assert(info.Effects[0].Effect == SPELL_EFFECT_SUMMON && !info.Effects[1].Effect);
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
    native = load("wind_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
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
    player = (ROOT / "src/server/game/Entities/Player/Player.cpp").read_text()
    code = code.replace("// NATIVE_REPLACEMENTS", "\n".join(native.extractor.extract(player, pattern) for pattern in [
        r"void Player::SetTemporarySpellReplacement\(", r"uint32 Player::GetTemporarySpellReplacement\("]))
    code = code.replace("struct SpellImplicitTargetInfo", "using WorldLocation = Position;\nstruct SpellImplicitTargetInfo")
    code = code.replace("int32 duration = 20000;", """int32 duration = 20000;
        uint8 MaxCharges = 0;
        uint32 ChargeRecoveryTime = 0, ChargeRecoveryKey = 0;
        float GetMaxRange(bool, Unit*) const { return 100.0f; }""")
    code = code.replace("struct SpellInfo\n", "struct Unit;\nstruct SpellInfo\n")
    code = code.replace("std::map<uint32, Aura> auras;", """std::map<uint32, Aura> auras;
        Unit* lastCastTarget = nullptr;
        bool inRange = true, raid = true, friendly = true;
        virtual bool IsInFlight() const { return false; }
        virtual bool GetVehicle() const { return false; }
        virtual bool GetTransport() const { return false; }
        bool IsWithinDistInMap(Unit* target, float range) const { assert(range == 100.0f); return target->inRange; }
        bool IsValidAssistTarget(Unit* target) const { return target->friendly; }
        bool IsInRaidWith(Unit* target) const { return target->raid; }""")
    code = code.replace("assert(target == this && triggered);", "assert(triggered); lastCastTarget = target;")
    code = code.replace("virtual bool Validate(SpellInfo const*)", "virtual bool Load() { return true; }\n    virtual bool Validate(SpellInfo const*)")
    code = code.replace("Unit* GetCaster() { return caster; }", """Unit* fixtureTarget = nullptr;
        WorldLocation* fixtureDestination = nullptr;
        WorldLocation const* GetHitDest() { return fixtureDestination; }
        Unit* GetExplTargetUnit() { return fixtureTarget; }
        Unit* GetHitUnit() { return fixtureTarget; }
        Unit* GetCaster() { return caster; }""")
    code = code.replace("virtual void OnPlayerLogin(Player*)", "virtual void OnPlayerLearnSpell(Player*, uint32) { }\n    virtual void OnPlayerLogin(Player*)")
    source = (ROOT / "src/server/coa/AscensionStormbringerWindGate.cpp").read_text()
    source = re.sub(r"^#include.*\n", "", source, flags=re.M)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    summon = native.extractor.extract(shared, r"TempSummon\* Player::SummonCreature\(")
    summon = summon.replace("TEMPSUMMON_MANUAL_DESPAWN", "TEMPSUMMON_TIMED_OR_DEAD_DESPAWN")
    summon = summon.replace("npc_ascension_runemaster_marker", "npc_ascension_stormbringer_gate")
    code += SUPPORT + (ROOT / "src/server/game/Spells/SpellChargeState.h").read_text() + source + summon + CASES
    with tempfile.TemporaryDirectory(prefix="coa-wind-gate-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "wind-gate")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT, faction INT,
            unit_class INT, type INT, ScriptName TEXT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale FLOAT, Probability FLOAT);
        CREATE TABLE creature_model_info (DisplayID INT, BoundingRadius FLOAT, CombatReach FLOAT, Gender INT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        INSERT INTO spell_script_names VALUES (504401, 'unrelated');
    """)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_07_wind_gate.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT CreatureID, CreatureDisplayID FROM creature_template_model").fetchall() == [(617478, 135809)]
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (3,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936]) if r[0] in {504401, 504643, 504644}}
        assert rows[504401][71:73] == (28, 27) and rows[504401][110:114:3] == (617478, 61)
        assert rows[504643][71] == 77 and rows[504643][86] == 57
        assert rows[504644][71] == 145 and rows[504644][86] == 21 and rows[504644][89] == 18
        assert rows[504644][110] == 300 and rows[504644][46] == 6
        tool = load("wind_models", ROOT / "apps/coa-spells/wind_gate.py")
        for table, captured in tool.ROWS.items():
            raw = (args.spell_dbc.parent / (table + ".dbc")).read_bytes()
            output = tool.transform(raw, table)
            assert tool.transform(output, table) == output
            old, strings = tool.dbc.read(raw, len(captured[0]))
            new, new_strings = tool.dbc.read(output, len(captured[0]))
            assert new[:len(old)] == old and new_strings[:len(strings)] == strings
            rune = tool.dbc.transform(raw, table)
            assert tool.dbc.transform(rune, table) == rune
    print("PASS: Wind Gate placement/ownership, ally pull guards, temporary ability, native charges and data")


if __name__ == "__main__":
    main()
