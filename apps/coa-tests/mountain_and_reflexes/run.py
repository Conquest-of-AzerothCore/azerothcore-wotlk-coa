CLI_DESCRIPTION = """Exercise actual Mountain/Reflexes scripts and the native dodge calculation."""
import argparse
import importlib.util
from pathlib import Path
import re
import sqlite3
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent
SUPPORT = r'''
struct DamageInfo
{
    uint32 amount = 10;
    SpellInfo* info = nullptr;
    uint32 GetDamage() const { return amount; }
    SpellInfo const* GetSpellInfo() const { return info; }
};
struct ProcEventInfo
{
    Unit* actor = nullptr;
    Unit* target = nullptr;
    DamageInfo* damage = nullptr;
    uint32 hit = PROC_HIT_DODGE;
    Unit* GetActor() { return actor; }
    Unit* GetActionTarget() { return target; }
    DamageInfo const* GetDamageInfo() { return damage; }
    uint32 GetHitMask() { return hit; }
};
struct AuraScript
{
    Unit* fixtureOwner = nullptr;
    uint32 caster = 1;
    uint8 stacks = 1;
    bool prevented = false;
    Hook DoCheckProc, OnEffectProc, AfterEffectApply;
    virtual bool Validate(SpellInfo const*) { return true; }
    virtual void Register() { }
    bool ValidateSpellInfo(std::initializer_list<uint32>) { return true; }
    Unit* GetTarget() { return fixtureOwner; }
    uint32 GetCasterGUID() { return caster; }
    uint8 GetStackAmount() { return stacks; }
    void PreventDefaultAction() { prevented = true; }
};
struct GlobalScript
{
    GlobalScript(char const*, std::initializer_list<int>) { }
    virtual void OnLoadSpellCustomAttr(SpellInfo*) { }
};
constexpr int GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1;
#define PrepareAuraScript(name)
#define AuraCheckProcFn(...) 0
#define AuraEffectProcFn(...) 0
#define AuraEffectApplyFn(...) 0
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("mountain_compile", args.workspace_tools / "Test-LocalLoginCollections.py")
    native = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(native)
    enums = []
    for path, names in [
        ("src/server/shared/SharedDefines.h", ["Classes", "Powers", "Stats", "SpellCastResult", "SpellMissInfo",
                                             "SpellEffects", "SpellEffIndex"]),
        ("src/server/game/Spells/SpellDefines.h", ["SpellModOp"]),
        ("src/server/game/Entities/Player/Player.h", ["SpellModType"]),
        ("src/server/game/Entities/Unit/Unit.h", ["DamageEffectType"]),
        ("src/server/game/Spells/Auras/SpellAuraDefines.h", ["AuraType", "AuraEffectHandleModes"]),
        ("src/server/game/Spells/SpellMgr.h", ["ProcFlagsHit"]),
    ]:
        source = (ROOT / path).read_text()
        enums.extend(native.extractor.extract(source, r"enum " + name + r"\b") + ";" for name in names)
    code = (HERE.parent / "pooled_vitality/harness.cpp").read_text().replace("// NATIVE_ENUMS", "\n".join(enums))
    code = "#define MAX_SPELLMOD 32\n" + code
    code = code.replace("struct EffectRecord {", "struct EffectRecord { int32 value=25; int32 CalcValue(Unit const*) const { return value; }")
    code = code.replace("std::array<EffectRecord, 3> Effects{};", "std::array<EffectRecord, 3> Effects{}; std::array<uint32,3> SpellFamilyFlags{};")
    code = code.replace("struct Player;", "struct Creature { bool IsTotem() const { return false; } bool isWorldBoss() const { return false; } }; struct Player;")
    code = code.replace("virtual Player* ToPlayer() { return nullptr; }", """virtual Player* ToPlayer() { return nullptr; }
        virtual Player const* ToPlayer() const { return nullptr; }
        Creature const* ToCreature() const { static Creature creature; return &creature; }
        float GetUnitDodgeChance() const;
        float GetTotalAuraModifier(AuraType) const { return 0; }
        bool HealthBelowPct(uint32 pct) const { return uint64(health)*100 < uint64(maxHealth)*pct; }
        bool IsValidAttackTarget(Unit* target) const { return target != this && target->IsAlive(); }
        bool IsFriendlyTo(Unit* target) const { return target == this; }""")
    code = code.replace("Player* ToPlayer() override { return this; }", """Player* ToPlayer() override { return this; }
        Player const* ToPlayer() const override { return this; }
        float GetRealDodge() const { return 7; }""")
    code += SUPPORT
    code += native.extractor.extract((ROOT / "src/server/game/Entities/Unit/Unit.cpp").read_text(),
                                     r"float Unit::GetUnitDodgeChance\(")
    for name in ["AscensionReaperReflexes.cpp", "AscensionPrimalistMountain.cpp"]:
        source = (ROOT / "src/server/coa" / name).read_text()
        code += re.sub(r'^#include.*\n', '', source, flags=re.M).replace(
            ": public AuraScript\n{", ": public AuraScript\n{\npublic:")
    code += HERE.joinpath("cases.cpp").read_text()
    with tempfile.TemporaryDirectory(prefix="coa-mountain-reflexes-") as directory:
        native.OUT = Path(directory)
        result = native.compile_run(code, "mountain-reflexes")
        assert result.returncode == 0, result.stdout + result.stderr
    db = sqlite3.connect(":memory:")
    db.executescript("CREATE TABLE spell_bonus_data (entry INT, direct_bonus REAL, dot_bonus REAL, "
                     "ap_bonus REAL, ap_dot_bonus REAL, comments TEXT);"
                     "CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT);"
                     "CREATE TABLE spell_proc (SpellId INT, ProcFlags INT, SpellTypeMask INT, SpellPhaseMask INT, "
                     "HitMask INT, AttributesMask INT, Chance INT);")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_14_mountain_and_reflexes.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    assert db.execute("SELECT ProcFlags, HitMask FROM spell_proc WHERE SpellId=705436").fetchone() == (40, 16)
    assert db.execute("SELECT direct_bonus, ap_bonus FROM spell_bonus_data").fetchone() == (0.1, 0.05)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {r[0]: r for r in struct.iter_unpack("<234I", raw[20:20 + count * 936])}
        assert rows[707454][80] + rows[707454][74] == 25
        assert rows[806068][49] == 5 and rows[806068][73] == 64 and rows[806068][118] == 680472
        assert rows[573050][71] == 9
    print("PASS: health-threshold dodge, dodge-only leech, Primal Rush/Quake gains and owned five-stack Mountain trigger")


if __name__ == "__main__":
    main()
