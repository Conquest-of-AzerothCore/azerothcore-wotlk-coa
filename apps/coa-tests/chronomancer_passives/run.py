CLI_DESCRIPTION = """Exercise Shimmering Shard's actual completed-cast hook and native helper contract."""
import argparse
import importlib.util
import re
from pathlib import Path
import struct
import sqlite3
import tempfile

ROOT = Path(__file__).resolve().parents[3]
CASES = r'''
int main()
{
    Player player;
    player.cls = CLASS_CHRONOMANCER;
    AeonSpell spell;
    spell.caster = &player;
    SpellInfo info;
    info.SpellFamilyName = 28;
    spell.info = &info;
    Hooks hooks;
    assert(spell.IsTriggered());
    for (uint32 id : {806290, 806291, 806292, 806293})
    {
        info.Id = id;
        auto before = player.casts.size();
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == before);
        player.AddAura(806302, &player);
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == before + 1);
        assert(player.casts.back().id == 806303 && player.casts.back().target == player.guid);
        spell.triggered = true;
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == before + 1);
        spell.triggered = false;
        player.RemoveAurasDueToSpell(806302);
    }
    for (uint32 id : {806290, 806291, 806292, 806293})
    {
        info.Id = id;
        player.AddAura(560310, &player);
        auto count = player.casts.size();
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == count + 1);
        assert(player.casts.back().id == 560311 && player.casts.back().target == player.guid);
        spell.triggered = true;
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == count + 1);
        spell.triggered = false;
        player.AddAura(806302, &player);
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == count + 3);
        assert(player.casts[count + 1].id == 806303 && player.casts[count + 2].id == 560311);
        player.RemoveAurasDueToSpell(806302);
        player.RemoveAurasDueToSpell(560310);
        hooks.OnSpellCast(&spell, &player, &info, false);
        assert(player.casts.size() == count + 3);
    }
    player.AddAura(560310, &player);
    player.AddAura(806302, &player);
    auto before = player.casts.size();
    info.Id = 806303;
    hooks.OnSpellCast(&spell, &player, &info, false);
    info.Id = 806291;
    player.cls = CLASS_RANGER;
    hooks.OnSpellCast(&spell, &player, &info, false);
    player.cls = CLASS_CHRONOMANCER;
    info.SpellFamilyName = 27;
    hooks.OnSpellCast(&spell, &player, &info, false);
    assert(player.casts.size() == before);
    info = {};
    info.Id = 804490;
    info.SpellFamilyName = 28;
    ApplyAscensionChronomancerTalentContracts(&info);
    assert(info.Effects[0].Effect == SPELL_EFFECT_DISPEL && info.Effects[0].CalcValue() == 1 &&
           info.Effects[0].MiscValue == DISPEL_ALL && info.targetMaskRebuilt);
    info = {};
    info.Id = 804451;
    info.SpellFamilyName = 28;
    info.Effects[0].ApplyAuraName = 42;
    info.Effects[0].TriggerSpell = 804470;
    ApplyAscensionChronomancerTalentContracts(&info);
    assert(info.Effects[0].ApplyAuraName == SPELL_AURA_DUMMY && !info.Effects[0].TriggerSpell);
    info = {};
    info.Id = 560310;
    info.SpellFamilyName = 28;
    info.ProcFlags = 2;
    info.Effects[0].ApplyAuraName = 42;
    info.Effects[0].TriggerSpell = 560311;
    ApplyAscensionChronomancerTalentContracts(&info);
    assert(!info.ProcFlags && info.Effects[0].ApplyAuraName == SPELL_AURA_DUMMY &&
           !info.Effects[0].TriggerSpell);
    info = {};
    info.Id = 806303;
    info.SpellFamilyName = 28;
    info.StackAmount = 3;
    info.Effects[0].BasePoints = 3;
    info.Effects[0].DieSides = 1;
    info.Effects[1].BasePoints = 1;
    info.Effects[1].DieSides = 1;
    ApplyAscensionChronomancerTalentContracts(&info);
    assert(info.Effects[1].CalcValue() == 4 && info.StackAmount == 3);
    player.x = 10;
    player.y = 20;
    player.z = 30;
    player.orientation = 1;
    Player other;
    other.guid = 2;
    other.x = 100;
    other.y = 200;
    other.z = 300;
    other.orientation = 2;
    SwapScript swap;
    swap.fixtureCaster = &player;
    swap.fixtureHit = &other;
    assert(swap.CheckSwap() == SPELL_CAST_OK);
    swap.Swap(EFFECT_0);
    assert(player.x == 100 && player.y == 200 && player.z == 300 && player.orientation == 2);
    assert(other.x == 10 && other.y == 20 && other.z == 30 && other.orientation == 1);
    assert(other.HasAura(803301, player.guid) && player.HasAura(803703, player.guid));
    player.RemoveAurasDueToSpell(803703);
    other.RemoveAurasDueToSpell(803301);
    other.friendly = true;
    swap.Swap(EFFECT_0);
    assert(player.x == 10 && other.x == 100 && !player.HasAura(803703) && !other.HasAura(803301));
    other.friendly = false;
    other.immuneSlow = true;
    swap.Swap(EFFECT_0);
    assert(!player.HasAura(803703)); // A resisted slow cannot grant free stolen speed.
    other.immuneSlow = false;
    for (bool Player::* blocked : {&Player::teleporting, &Player::flight, &Player::transport, &Player::vehicle})
        for (Player* actor : {&player, &other})
        {
            actor->*blocked = true;
            assert(swap.CheckSwap() == SPELL_FAILED_BAD_TARGETS);
            float previous = player.x;
            swap.Swap(EFFECT_0);
            assert(player.x == previous);
            actor->*blocked = false;
        }
    for (bool Unit::* required : {&Unit::alive, &Unit::inWorld, &Unit::samePhase, &Unit::los})
        for (Player* actor : {&player, &other})
        {
            actor->*required = false;
            assert(swap.CheckSwap() == SPELL_FAILED_BAD_TARGETS);
            actor->*required = true;
        }
    other.map = 2;
    assert(swap.CheckSwap() == SPELL_FAILED_BAD_TARGETS);
    other.map = 1;
    swap.fixtureHit = &player;
    assert(swap.CheckSwap() == SPELL_FAILED_BAD_TARGETS);
    Unit creature;
    swap.fixtureHit = &creature;
    assert(swap.CheckSwap() == SPELL_FAILED_BAD_TARGETS);
    info.Id = 802790;
    info.Effects[0].Effect = SPELL_EFFECT_DUMMY;
    info.Effects[1].Effect = info.Effects[2].Effect = SPELL_EFFECT_TELEPORT_UNITS;
    ApplyAscensionChronomancerTalentContracts(&info);
    assert(info.Effects[0].Effect == SPELL_EFFECT_DUMMY && !info.Effects[1].Effect && !info.Effects[2].Effect);
    assert(info.targetMaskRebuilt);
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("doctor_fixture",
                                                 args.workspace_tools / "Test-WitchDoctorCompletion.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    read = fixture.read
    def fixture_read(path):
        code = read(path)
        if path.name == "WitchDoctorCompletionHarness.cpp":
            for name, value in (("SPELL_EFFECT_DISPEL", 38), ("DISPEL_ALL", 7)):
                if not re.search(r"\b" + name + r"\b", code):
                    code += f"\nconstexpr uint32 {name}={value};\n"

            code = code.replace("struct Position {};", "struct Position { float x=0,y=0,z=0,orientation=0; };")
            code = code.replace("float ap=1000", "float y=0,z=0,orientation=0; bool immuneSlow=false; float ap=1000")
            code = code.replace("Position GetPosition()const{return {};}",
                "Position GetPosition()const{return {x,y,z,orientation};}")
            code = code.replace("bool exists=t->HasAura(id);", "if(id==803301&&t->immuneSlow)return; bool exists=t->HasAura(id);")
            code = code.replace("struct Player:Unit {", "struct Player:Unit { "
                "uint32 map=1; bool teleporting=false,flight=false,transport=false,vehicle=false; "
                "uint32 GetMap() const { return map; } bool IsBeingTeleported() const { return teleporting; } "
                "bool IsInFlight() const { return flight; } void* GetTransport() { return transport?this:nullptr; } "
                "void* GetVehicle() { return vehicle?this:nullptr; } "
                "bool IsValidAssistTarget(Unit* target) { return IsFriendlyTo(target); } "
                "void NearTeleportTo(Position& p, bool=false) { x=p.x; y=p.y; z=p.z; orientation=p.orientation; }")
            if not re.search(r"\bProcFlags\b", fixture.extract(code, r"struct SpellInfo\b")):
                code = code.replace("struct SpellInfo {", "struct SpellInfo { uint32 ProcFlags=0; ")
            code = code.replace("struct SpellInfo {", "struct SpellInfo { bool targetMaskRebuilt=false; "
                "void _InitializeExplicitTargetMask() { targetMaskRebuilt=true; }")
        return code
    fixture.read = fixture_read
    source = (ROOT / "src/server/coa/AscensionChronomancerTalents.cpp").read_text()
    production = fixture.extract(source, r"enum ChronomancerTalentSpells\b") + ";\n"
    production += fixture.fn(source, "IsAeonActivation")
    production += fixture.fn(source, "CanSwapPlayers")
    production += "using SpellEffIndex=uint32; struct SwapScript:Context { Unit* fixtureHit=nullptr; "
    production += "Unit* GetExplTargetUnit() { return fixtureHit; } Unit* GetHitUnit() { return fixtureHit; }\n"
    production += fixture.extract(source, r"SpellCastResult CheckSwap\(\)")
    production += fixture.fn(source, "Swap") + "};\n"
    production += "constexpr uint32 TRIGGERED_IGNORE_GCD=1; struct AeonSpell:Spell { "
    production += "bool IsTriggered() const { return true; } "
    production += "bool HasTriggeredCastFlag(uint32 flag) const { "
    production += "assert(flag==TRIGGERED_IGNORE_GCD); return triggered; } };\n"
    hook = fixture.fn(source, "OnSpellCast").replace("Spell* spell", "AeonSpell* spell")
    production += "struct Hooks {\n" + hook + "};\n"
    production += fixture.fn(source, "ApplyAscensionChronomancerTalentContracts")
    with tempfile.TemporaryDirectory(prefix="coa-chronomancer-passives-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("chronomancer-passives", production, CASES)
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT)")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_03_dimensional_divergence.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert list(db.execute("SELECT * FROM spell_script_names")) == [(802790, "spell_ascension_dimensional_divergence")]
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {806290, 806291, 806292, 806293, 806302, 806303, 806727, 802790, 803301, 803703}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        for sid in range(806290, 806294):
            assert rows[sid][8] & 0x80
            assert rows[sid][208:212] == (28, 0, 64, 0)
        assert rows[806303][71:73] == (6, 6) and rows[806303][95:97] == (79, 136)
        assert rows[806303][80] + rows[806303][74] == 4
        assert rows[806303][40] == 18 and rows[806303][49] == 3
        assert rows[806727][71:74] == (124, 108, 108)
        assert rows[806727][86:89] == (57, 57, 57) and rows[806727][111:113] == (7, 11)
        assert rows[802790][71:74] == (3, 5, 5) and rows[802790][86] == 25
        assert rows[803301][95] == 33 and rows[803703][95] == 31
        assert rows[803301][80] - 2**32 + rows[803301][74] == -80
        assert rows[803703][80] + rows[803703][74] == 80
        assert rows[803301][40] == rows[803703][40] == 27
    print("PASS: Aeon triggers, equal damage/healing, live-position swaps, movement gates, resisted slow and native helpers")


if __name__ == "__main__":
    main()
