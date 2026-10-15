CLI_DESCRIPTION = """Regress Light Arrows, Knockout and the actual Ranger spender path."""
import argparse
import importlib.util
from pathlib import Path
import sqlite3
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
CASES = r'''
int main()
{
    Player player;
    player.cls = CLASS_RANGER;
    Unit enemy;
    enemy.guid = 2;
    for (float distance : {39.9f, 40.0f, 40.1f})
    {
        enemy.x = distance;
        Light light;
        light.fixtureCaster = &player;
        light.fixtureHit = &enemy;
        assert(light.Load());
        light.Snapshot();
        light.hitDamage = 1000;
        light.Damage();
        assert(light.hitDamage == 1000);
        player.AddAura(681292, &player)->GetEffect(0)->amount = 20;
        light.Snapshot();
        enemy.x = 5; // The projectile keeps the launch-time range decision.
        light.Damage();
        assert(light.hitDamage == (distance >= 40 ? 1200 : 1000));
        player.RemoveAurasDueToSpell(681292);
    }
    player.cls = CLASS_WITCH_DOCTOR;
    Light foreign;
    foreign.fixtureCaster = &player;
    assert(!foreign.Load());
    player.cls = CLASS_RANGER;
    Knockout knockout;
    knockout.fixtureCaster = &player;
    knockout.fixtureHit = &enemy;
    knockout.Incapacitate(EFFECT_1);
    assert(player.casts.back().id == 706762 && player.casts.back().target == enemy.guid);
    SpellInfo knockoutInfo;
    knockoutInfo.Id = 706762;
    knockoutInfo.SpellFamilyName = 27;
    ApplyAscensionRangerTalentContracts(&knockoutInfo);
    assert(knockoutInfo.AuraInterruptFlags & AURA_INTERRUPT_FLAG_TAKE_DAMAGE);
    SpellDurationEntry snatchDuration;
    snatchDuration.ID = 35;
    manager.rows[803115].DurationEntry = &snatchDuration;
    SpellInfo snatch;
    snatch.Id = 803123;
    snatch.SpellFamilyName = 27;
    ApplyAscensionRangerTalentContracts(&snatch);
    assert(snatch.DurationEntry == &snatchDuration);
    SpellInfo info;
    info.Id = 802036;
    info.SpellFamilyName = 27;
    info.CasterAuraSpell = SPELL_RANGER_ADVANTAGE;
    Spell spell;
    spell.caster = &player;
    spell.info = &info;
    TargetInfo target;
    target.targetGUID = enemy.guid;
    spell.fixtureTargets = {target};
    auto count = [&] {
        return std::count_if(player.casts.begin(), player.casts.end(), [](auto const& cast) { return cast.id == 524653; });
    };
    player.AddAura(680276, &player);
    player.AddAura(524654, &player);
    for (uint32 family : {32768u, 134217728u})
        for (bool consume : {false, true})
            for (uint8 stacks : std::array<uint8, 2>{4, 5})
            {
                info.SpellFamilyFlags[1] = family;
                player.AddAura(SPELL_RANGER_ADVANTAGE, &player)->stacks = stacks;
                randomSuccess = consume;
                auto before = count();
                Consumer(&spell, &player);
                assert(count() == before + (stacks == 5 ? 1 : 0));
            }
    auto before = count();
    spell.fixtureTargets[0].missCondition = SPELL_MISS_MISS;
    Consumer(&spell, &player);
    assert(count() == before);
    spell.fixtureTargets[0].missCondition = SPELL_MISS_NONE;
    info.SpellFamilyFlags[1] = 1;
    Consumer(&spell, &player);
    assert(count() == before);
    info.SpellFamilyFlags[1] = 32768;
    player.RemoveAurasDueToSpell(524654);
    Consumer(&spell, &player);
    assert(count() == before);
    player.AddAura(524654, &player);
    player.GetAura(680276)->caster = 99;
    Consumer(&spell, &player);
    assert(count() == before);
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--source-ref", help="Use an older Ranger spender as a negative control")
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
            code = code.replace("struct SpellInfo {", "struct SpellInfo { uint32 CasterAuraSpell=0;")
            code = code.replace("struct TargetInfo {", "struct TargetInfo { ObjectGuid targetGUID;")
            code = code.replace("struct Spell {", "struct Spell { std::vector<TargetInfo> fixtureTargets; "
                "auto const* GetUniqueTargetInfo() const { return &fixtureTargets; }")
            code = code.replace("struct Player:Unit {", "struct Player:Unit { "
                "void ApplySpellMod(uint32, uint32, float&, Spell*) { }")
            code = code.replace("bool IsInWorld()const", "float GetExactDist(Unit* target) const { "
                "return std::abs(x-target->x); } bool IsInWorld()const")
        return code
    fixture.read = fixture_read
    source = (ROOT / "src/server/coa/AscensionRangerTalents.cpp").read_text()
    production = "using SpellEffIndex=uint32;\n"
    production += fixture.extract(source, r"enum RangerTalentSpells\b") + ";\n"
    production += "#include <limits>\nstruct Light:Context { int32 _bonus=0, hitDamage=0; Unit* fixtureHit=nullptr; "
    production += "Unit* GetExplTargetUnit() { return fixtureHit; } int32 GetHitDamage() { return hitDamage; } "
    production += "void SetHitDamage(int32 amount) { hitDamage=amount; }\n"
    light = fixture.extract(source, r"class spell_ascension_ranger_light_arrows\b")
    production += "\n".join(fixture.fn(light, name) for name in ["Load", "Snapshot", "Damage"]) + "};\n"
    production += ("struct Knockout:Context { Unit* fixtureHit=nullptr; Unit* GetHitUnit() { return fixtureHit; }\n" +
                   fixture.fn(source, "Incapacitate") + "};\n")
    production += fixture.fn(source, "HandleAscensionRangerStonemason")
    production += fixture.fn(source, "ApplyAscensionRangerTalentContracts")
    mechanics = ((ROOT / "src/server/coa/AscensionClassMechanics.cpp").read_text()
        if not args.source_ref else git_source(["git", "show",
            f"{args.source_ref}:src/server/coa/AscensionClassMechanics.cpp"], cwd=ROOT).decode("utf-8"))
    production += fixture.fn(mechanics, "DidRangerAdvantageConsumerSucceed")
    production += ("constexpr uint32 SPELL_RANGER_ADVANTAGE=804329, SPELL_RANGER_ADVANTAGE_DECREMENT=520618, "
                   "SPELL_RANGER_ADVANTAGE_DECREMENT_PASSIVE=582770; "
                   "void HandleRangerAdvantageSpent(Player*, uint8) {}\n")
    block = fixture.extract(mechanics, r"if \(player->getClass\(\) == CLASS_RANGER &&\s*"
        r"info->CasterAuraSpell == SPELL_RANGER_ADVANTAGE\)")
    production += "void Consumer(Spell* spell, Player* player) { auto info=spell->GetSpellInfo();\n" + block + "}\n"
    with tempfile.TemporaryDirectory(prefix="coa-ranger-passives-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("ranger-passives", production, CASES)
    db = sqlite3.connect(":memory:")
    db.execute("CREATE TABLE spell_script_names (spell_id INT, ScriptName TEXT)")
    sql = (ROOT / "data/sql/updates/pending_db_world/rev_20260914_02_ranger_talents.sql").read_text()
    db.executescript(sql)
    before = list(db.iterdump())
    db.executescript(sql)
    assert before == list(db.iterdump())
    ranks = {500075, *range(572108, 572114)}
    assert {row[0] for row in db.execute("SELECT spell_id FROM spell_script_names WHERE "
        "ScriptName='spell_ascension_ranger_light_arrows'")} == ranks
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in ranks | {801435, 706762, 706763, 524653}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert rows[801435][71:73] == (140, 3) and rows[801435][116] == 706763
        assert rows[706762][95] == 12 and rows[706762][3] == 14
        assert rows[706763][72:74] == (108, 38) and rows[706763][111:113] == (15, 4)
        assert rows[524653][71] == 177 and rows[524653][110] == 680276
        assert rows[524653][80] + rows[524653][74] == 6000
        for sid in ranks:
            assert rows[sid][71] == 2 and rows[sid][208] == 27
    print("PASS: 40-yard snapshot, complete damage bonus, Knockout helper, five-stack use/preservation and misses")


if __name__ == "__main__":
    main()
