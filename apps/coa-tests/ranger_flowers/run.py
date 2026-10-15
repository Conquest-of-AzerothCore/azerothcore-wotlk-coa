CLI_DESCRIPTION = """Exercise green flower creation, critical/cast triggers, pickup selection and Highlander."""
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
struct AllSpellScript
{
    AllSpellScript(char const*, std::initializer_list<int>) { }
    virtual void OnSpellCast(Spell*, Unit*, SpellInfo const*, bool) { }
};
constexpr int GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1, ALLSPELLHOOK_ON_CAST = 1;
// SQL independently limits the identity proc to critical hits and a 1000 ms cooldown.
constexpr uint32 PROC_HIT_CRITICAL = 2;
bool chancePass = true;
bool roll_chance_i(uint32 chance) { assert(chance == 20); return chancePass; }
struct DamageInfo { uint32 amount = 1; uint32 GetDamage() { return amount; } };
struct ProcEventInfo
{
    Unit* actor;
    Unit* victim;
    DamageInfo* damage;
    uint32 hit = PROC_HIT_CRITICAL;
    Unit* GetActor() { return actor; }
    Unit* GetActionTarget() { return victim; }
    DamageInfo* GetDamageInfo() { return damage; }
    uint32 GetHitMask() { return hit; }
};
struct AuraEffect { };
struct AuraScript
{
    Unit* target = nullptr;
    bool prevented = false;
    Hook DoCheckProc, OnEffectProc;
    virtual void Register() { }
    Unit* GetTarget() { return target; }
    void PreventDefaultAction() { prevented = true; }
};
void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid caster)
{
    if (HasAura(id, caster)) auras.erase(id);
}
#define PrepareAuraScript(name)
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define SpellCastFn(...) 0
#define SpellHitFn(...) 0
#define SpellObjectAreaTargetSelectFn(...) 0
'''


def make_harness(native, source_path, ai_name):
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
    code = "#include <algorithm>\n#include <cmath>\n#include <list>\n" + code
    code = code.replace("struct SpellImplicitTargetInfo", "using WorldLocation = Position;\nstruct Unit;\nstruct SpellImplicitTargetInfo")
    code = code.replace("uint32 target = 0;", "uint32 target = 0;\n    uint32 GetTarget() const { return target; }")
    code = code.replace("uint32 Effect = 0;", """uint32 Effect = 0, MiscValue = 0, TriggerSpell = 0;
        int32 MiscValueB = 0, BasePoints = 0, DieSides = 0;
        float RealPointsPerLevel = 0;""")
    code = code.replace("struct SpellInfo\n{", "struct SpellInfo\n{\n    SpellInfo() { }")
    code = code.replace("int32 duration = 20000;", """int32 duration = 20000;
        uint32 StackAmount = 3, ProcChance = 20, CasterAuraSpell = 0;
        std::array<uint32, 3> SpellFamilyFlags{};
        uint32 CalcMaxAuraStacks(Unit*) const { return StackAmount; }""")
    code = code.replace("ObjectGuid caster;", """ObjectGuid caster;
        uint32 stacks = 1;
        SpellInfo info;
        uint32 GetStackAmount() const { return stacks; }
        SpellInfo const* GetSpellInfo() const { return &info; }""")
    code = code.replace("std::map<uint32, Aura> auras;", """std::map<uint32, Aura> auras;
        bool raid = true, friendly = true, combat = true;
        virtual Creature* ToCreature() { return nullptr; }
        Unit* ToUnit() { return this; }
        bool IsPlayer() const { return const_cast<Unit*>(this)->ToPlayer() != nullptr; }
        virtual uint32 getClass() const { return 0; }
        bool IsInCombat() const { return combat; }
        bool IsValidAssistTarget(Unit* target) const { return target->friendly; }
        bool IsValidAttackTarget(Unit* target) const { return !target->friendly; }
        bool IsFriendlyTo(Unit* target) const { return target->friendly; }
        bool IsInRaidWith(Unit* target) const { return target->raid; }
        float GetExactDist(Unit const* target) const { return std::abs(position.x - target->position.x); }
        Aura* GetAura(uint32 id, ObjectGuid caster) { return HasAura(id, caster) ? &auras.at(id) : nullptr; }""")
    code = code.replace("bool HasAura(uint32 id, ObjectGuid caster) const", "bool HasAura(uint32 id, ObjectGuid caster = {}) const")
    code = code.replace("it->second.caster == caster;", "(!caster || it->second.caster == caster);")
    code = code.replace("assert(target == this && triggered);", "assert(triggered); (void)target;")
    code = code.replace("if (id == 500289 || id == 500588)\n            auras[id] = {id, guid};", """if (id == 707539 || id == 712427 || id == 561006)
        {
            if (HasAura(id, guid)) auras[id].stacks = std::min(3u, auras[id].stacks + 1);
            else auras[id] = {id, guid};
        }""")
    code = code.replace("uint32 GetEntry() const", "Creature* ToCreature() override { return this; }\n    uint32 GetEntry() const")
    code = code.replace("virtual bool Validate(SpellInfo const*)", "virtual bool Load() { return true; }\n    virtual bool Validate(SpellInfo const*)")
    code = code.replace("Hook OnCheckCast,", "Hook OnObjectAreaTargetSelect, BeforeCast, AfterCast, OnHit, OnCheckCast,")
    code = code.replace("Unit* GetCaster() { return caster; }", """Unit* fixtureTarget = nullptr;
        WorldLocation* fixtureDestination = nullptr;
        WorldLocation const* GetHitDest() { return fixtureDestination; }
        Unit* GetHitUnit() { return fixtureTarget; }
        Unit* GetCaster() { return caster; }""")
    source = source_path.read_text()
    source = re.sub(r"^#include.*\n", "", source, flags=re.M)
    source = source.replace(": public SpellScript\n{", ": public SpellScript\n{\npublic:")
    source = source.replace(": public AuraScript\n{", ": public AuraScript\n{\npublic:")
    summon = native.extractor.extract(shared, r"TempSummon\* Player::SummonCreature\(")
    summon = summon.replace("TEMPSUMMON_MANUAL_DESPAWN", "TEMPSUMMON_TIMED_OR_DEAD_DESPAWN")
    summon = summon.replace("npc_ascension_runemaster_marker", ai_name)
    return code + SUPPORT + source + summon


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("flower_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    code = make_harness(native, ROOT / "src/server/coa/AscensionRangerFlowers.cpp",
                        "npc_ascension_ranger_flower")
    code += Path(__file__).with_name("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-ranger-flowers-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "ranger-flowers")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE creature_template (entry INT, name TEXT, minlevel INT, maxlevel INT, faction INT,
            unit_class INT, type INT, ScriptName TEXT);
        CREATE TABLE creature_template_model (CreatureID INT, Idx INT, CreatureDisplayID INT,
            DisplayScale FLOAT, Probability FLOAT);
        CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);
        CREATE TABLE spell_proc (SpellId INT, ProcFlags INT, SpellTypeMask INT, SpellPhaseMask INT,
            HitMask INT, AttributesMask INT, Chance INT, Cooldown INT);
        INSERT INTO spell_script_names VALUES (92117, 'unrelated');
    """)
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_10_ranger_green_flowers.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT CreatureDisplayID FROM creature_template_model").fetchone() == (100003,)
    assert db.execute("SELECT * FROM spell_proc").fetchone() == (92117, 332116, 1, 2, 2, 2, 100, 1000)
    assert db.execute("SELECT COUNT(*) FROM spell_script_names").fetchone() == (17,)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])}
        for sid in [561005, 800246, 803507, 803508, 803510, 803720]:
            assert rows[sid][71] == 28 and rows[sid][110] == 454239
        assert rows[561005][92] == 18 and rows[561005][40] == 1
        assert rows[561006][96] == 23 and rows[561006][99] == 300 and rows[561006][117] == 561008
        assert rows[561008][71] == 64 and rows[561008][116] == 561007 and rows[561008][92] == 7 and rows[561008][212] == 1
        assert rows[561007][71:74] == (6, 136, 1) and rows[561007][81] + rows[561007][75] == 5
        assert (rows[561007][82] + rows[561007][76]) & 0xFFFFFFFF == 0 and rows[561007][88] == 1
        assert rows[707539][49] == 3 and rows[712427][96] == 108 and rows[712427][111] == 14
        assert (rows[712427][81] + rows[712427][75]) & 0xFFFFFFFF == 0xFFFFFF9C and rows[712427][126] == 4194304
        assert rows[712428][95] == 118 and (rows[712428][80] + rows[712428][74]) & 0xFFFFFFFF == 0xFFFFFFD8
        assert rows[800150][35] == 20 and rows[807237][209] == 32768
        for sid in [806345, *range(806437, 806444)]:
            assert rows[sid][210] == 4194304
    print("PASS: green flower summons, pickup eligibility, crit/cast triggers, Highlander and native helper data")


if __name__ == "__main__":
    main()
