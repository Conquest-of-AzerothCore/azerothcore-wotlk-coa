CLI_DESCRIPTION = """Test Jungle Secrets with production callbacks and the existing completion fixture."""
import argparse
import importlib.util
from pathlib import Path
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
    player.friendly = true;
    Unit primary, low, high;
    primary.guid = 2;
    low.guid = 3;
    high.guid = 4;
    primary.friendly = low.friendly = high.friendly = true;
    primary.health = 100;
    low.health = 200;
    high.health = 400;
    Creature effigy;
    effigy.guid = 5;
    effigy.entry = NpcShadow;
    effigy.ownerGuid = player.guid;
    world[effigy.guid] = &effigy;
    State(&player).summons = {effigy.guid, ObjectGuid(99)};
    neighborhood = {&high, &primary, &low};
    SpellInfo brew;
    brew.Id = LoaBrew;
    brew.SpellFamilyFlags = {0, 131072, 0};
    Spell spell;
    spell.info = &brew;
    spell.caster = &player;
    Hits hits;
    manager.rows[JungleSecrets].Effects[0].BasePoints = 34;
    manager.rows[JungleSecretsHeal].Effects[0].fixtureRadius = 10.0f;
    auto run = [&](uint32 healing = 1000, SpellMissInfo miss = SPELL_MISS_NONE) {
        player.casts.clear();
        hits.OnSpellHitResult(&spell, &primary, uint8(miss), 0, healing, false);
    };
    auto copies = [&] {
        std::vector<RecordedCast> result;
        for (auto const& cast : player.casts)
            if (cast.id == JungleSecretsHeal)
                result.push_back(cast);
        return result;
    };
    run();
    assert(copies().empty());
    player.AddAura(JungleSecrets, &player);
    run();
    assert(copies().size() == 1 && copies()[0].target == low.guid && copies()[0].amount == 350);
    run(0);
    assert(copies().empty());
    run(1000, SPELL_MISS_IMMUNE);
    assert(copies().empty());
    for (uint32 entry : {NpcShadow, NpcHexing, NpcCursed, NpcGraven})
    {
        effigy.entry = entry;
        run(999);
        assert(copies().size() == 1 && copies()[0].amount == 349);
    }
    effigy.entry = NpcHealing;
    run();
    assert(copies().empty());
    effigy.entry = NpcShadow;
    effigy.ownerGuid = 42;
    run();
    assert(copies().empty());
    effigy.ownerGuid = player.guid;
    effigy.alive = false;
    run();
    assert(copies().empty());
    effigy.alive = true;
    effigy.samePhase = false;
    run();
    assert(copies().empty());
    effigy.samePhase = true;
    effigy.sameMap = false;
    run();
    assert(copies().empty());
    effigy.sameMap = true;
    effigy.x = 50;
    run();
    assert(copies().empty());
    low.x = 50; // Selection is centered on the effigy, not the Doctor or primary recipient.
    run();
    assert(copies().size() == 1 && copies()[0].target == low.guid);
    effigy.x = low.x = 0;
    for (bool Unit::* gate : {&Unit::alive, &Unit::raid, &Unit::friendly, &Unit::los,
                             &Unit::sameMap, &Unit::samePhase})
    {
        low.*gate = false;
        run();
        assert(copies().size() == 1 && copies()[0].target == high.guid);
        low.*gate = true;
    }
    neighborhood = {&primary};
    run();
    assert(copies().empty());
    neighborhood = {&low};
    player.cls = CLASS_BARBARIAN;
    run();
    assert(copies().empty());
    player.cls = CLASS_WITCH_DOCTOR;
    brew.SpellFamilyFlags = {};
    run();
    assert(copies().empty());
    // The helper is a resolved, noncritical heal with one explicit ally target.
    SpellInfo info;
    info.Id = JungleSecretsHeal;
    info.DmgClass = SPELL_DAMAGE_CLASS_MAGIC;
    info.Effects[0].Effect = SPELL_EFFECT_HEAL;
    info.Effects[0].TargetA = SpellImplicitTargetInfo(87);
    info.Effects[0].TargetB = SpellImplicitTargetInfo(31);
    info.Effects[0].BonusMultiplier = 1.0f;
    ApplyContracts(&info);
    assert(info.DmgClass == SPELL_DAMAGE_CLASS_NONE && info.AscensionInheritsResolvedAmount);
    assert(info.AttributesEx2 & SPELL_ATTR2_CANT_CRIT);
    assert(info.AttributesEx3 & SPELL_ATTR3_IGNORE_CASTER_MODIFIERS);
    assert(!info.Effects[0].BonusMultiplier && info.Effects[0].TargetA.GetTarget() == TARGET_UNIT_TARGET_ALLY);
    assert(!info.Effects[0].TargetB.GetTarget() && info.fixtureMaskUpdates == 1);
    for (uint32 id : {DevotionHeal, LoaEchoHeal, WaveHeal, ThistleHeal, ConcoctionsHeal, FrenzyHeal})
    {
        info = {};
        info.Id = id;
        info.Effects[0].Effect = SPELL_EFFECT_HEAL;
        info.Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        ApplyContracts(&info);
        assert(info.Effects[0].TargetA.GetTarget() == TARGET_UNIT_TARGET_ALLY);
        assert(info.fixtureMaskUpdates == 1); // Explicit targets must survive Spell::InitExplicitTargets.
    }
    for (uint32 id : {ThreadsDamage, BottleDamage, StringsDamage, GuileDamage})
    {
        info = {};
        info.Id = id;
        info.Effects[0].Effect = SPELL_EFFECT_SCHOOL_DAMAGE;
        info.Effects[0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        ApplyContracts(&info);
        assert(info.Effects[0].TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY && info.fixtureMaskUpdates == 1);
    }
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--workspace-tools", type=Path, default=ROOT.parent / "tools")
    parser.add_argument("--source-ref", help="Use older Witch Doctor callbacks and contracts as a negative control")
    parser.add_argument("--spell-dbc", type=Path)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("doctor_completion_fixture",
                                                 args.workspace_tools / "Test-WitchDoctorCompletion.py")
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    fixture.MODULE = ROOT / "src/server/coa"
    read = fixture.read
    def fixture_read(path):
        code = read(path)
        if path.name == "WitchDoctorCompletionHarness.cpp":
            code = code.replace("struct SpellEffectInfo {", "struct SpellEffectInfo { "
                "float fixtureRadius=0; float CalcRadius(Unit*) const { return fixtureRadius; }")
            code = code.replace("struct SpellInfo {", "struct SpellInfo { uint32 DmgClass=0, fixtureMaskUpdates=0; "
                "bool AscensionInheritsResolvedAmount=false; "
                "void _InitializeExplicitTargetMask() { ++fixtureMaskUpdates; }")
            code = code.replace("namespace ObjectAccessor {", "struct Creature : Unit {}; namespace ObjectAccessor { "
                "Creature* GetCreature(Unit&, ObjectGuid id) { "
                "return world.contains(id)?dynamic_cast<Creature*>(world.at(id)):nullptr; }")
        return code
    fixture.read = fixture_read
    source = fixture.source
    if args.source_ref:
        fixture.source = lambda part: (git_source(["git", "show",
            f"{args.source_ref}:src/server/coa/AscensionWitchDoctor{part}.cpp"],
            cwd=ROOT).decode("utf-8") if part in {"Abilities", "Completion"} else source(part))
    production = read(fixture.MODULE / "AscensionWitchDoctorCoefficients.h")
    production += "\nnamespace AscensionWitchDoctor {\n"
    production += fixture.methods("Summons", ["Slot", "HealThroughEffigies"])
    production += fixture.methods("Brewing", ["SyncIngredients", "IngredientChanged", "Mix", "IngredientMask",
                                             "PotionEffects"])
    production += fixture.methods("Completion", ["ApplyContracts"]) + "\n}\n"
    production += fixture.methods("Abilities", ["RefreshOwnedHex"])
    production += fixture.wrapper("Hits", "Abilities", ["OnSpellHitResult"])
    with tempfile.TemporaryDirectory(prefix="coa-doctor-passives-") as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp("jungle-secrets", production, CASES)
    if args.spell_dbc:
        raw = args.spell_dbc.read_bytes()
        count = struct.unpack_from("<I", raw, 4)[0]
        rows = {}
        for offset in range(20, 20 + count * 936, 936):
            sid = struct.unpack_from("<I", raw, offset)[0]
            if sid in {707212, 712348}:
                rows[sid] = struct.unpack_from("<234I", raw, offset)
        assert rows[707212][80] + rows[707212][74] == 35 and rows[712348][92] == 9
        assert rows[712348][71] == 10 and rows[712348][208] == 19
    print("PASS: Brew dispatch, effective-heal share, effigy ownership, smart selection and copied-effect target masks")


if __name__ == "__main__":
    main()
