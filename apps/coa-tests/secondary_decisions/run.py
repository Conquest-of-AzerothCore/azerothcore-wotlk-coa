CLI_DESCRIPTION = """Execute the approved Warpath and Vampiric Pools metadata with the existing native fixture."""
import argparse
import importlib.util
from pathlib import Path
import struct
import tempfile

ROOT = Path(__file__).resolve().parents[3]
CASES = r'''
int main()
{
    SpellInfo warpath;
    warpath.Id = SPELL_WARPATH_PROTECTION;
    warpath.Effects[0].Effect = SPELL_EFFECT_APPLY_AURA;
    warpath.Effects[0].ApplyAuraName = SPELL_AURA_MOD_MINIMUM_SPEED;
    warpath.Effects[0].BasePoints = 89;
    warpath.DurationEntry = sSpellDurationStore.LookupEntry(21);
    ApplyContracts(&warpath);
    assert(warpath.DurationEntry->ID == 27 && warpath.Effects[0].CalcValue() == 90);
    warpath.SpellFamilyName = 3;
    warpath.DurationEntry = sSpellDurationStore.LookupEntry(21);
    ApplyContracts(&warpath);
    assert(warpath.DurationEntry->ID == 21);

    bloodmage_talent_contracts contracts;
    SpellInfo pools;
    pools.Id = SPELL_VAMPIRIC_POOLS_LEECH;
    pools.SpellFamilyName = 26;
    pools.ProcFlags = 664232;
    pools.MaxAffectedTargets = 5;
    auto& leech = pools.Effects[0];
    leech.Effect = SPELL_EFFECT_HEALTH_LEECH;
    leech.BasePoints = 95;
    leech.DieSides = 6;
    leech.BonusMultiplier = 1.0f;
    leech.TargetA = SpellImplicitTargetInfo(22);
    leech.TargetB = SpellImplicitTargetInfo(15);
    leech.RadiusEntry = sSpellRadiusStore.LookupEntry(8);
    contracts.OnLoadSpellCustomAttr(&pools);
    assert(pools.DurationEntry->ID == 32);
    auto const& fear = pools.Effects[1];
    assert(fear.Effect == SPELL_EFFECT_APPLY_AURA && fear.ApplyAuraName == SPELL_AURA_MOD_FEAR);
    assert(fear.Mechanic == MECHANIC_FEAR && (pools.AttributesCu & SPELL_ATTR0_CU_NEGATIVE_EFF1));
    assert(fear.TargetA.target == 22 && fear.TargetB.target == 15 && fear.RadiusEntry == leech.RadiusEntry);
    assert(leech.Effect == SPELL_EFFECT_HEALTH_LEECH && leech.BasePoints == 95 && leech.DieSides == 6);
    assert(leech.BonusMultiplier == 1.0f && pools.MaxAffectedTargets == 5 && pools.ProcFlags == 664232);
    pools.SpellFamilyName = 3;
    pools.DurationEntry = nullptr;
    pools.Effects[1].Effect = 0;
    contracts.OnLoadSpellCustomAttr(&pools);
    assert(!pools.DurationEntry && !pools.Effects[1].Effect);
    contracts.OnLoadSpellCustomAttr(nullptr);
}
'''


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--workspace-tools', type=Path, default=ROOT.parent / 'tools')
    parser.add_argument('--spell-dbc', type=Path, required=True)
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location('xoroth_fixture',
                                                args.workspace_tools / 'Test-KnightOfXorothCompletion.py')
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    fixture.M = ROOT / 'src/server/coa'
    source = (fixture.M / 'AscensionBloodmageTalents.cpp').read_text()
    production = 'constexpr int GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR = 1;\n'
    production += 'struct GlobalScript { GlobalScript(char const*, std::initializer_list<int>) {} '
    production += 'virtual void OnLoadSpellCustomAttr(SpellInfo*) {} };\n'
    production += fixture.native.extractor.extract(source, r'enum BloodmageTalentSpells\b') + ';\n'
    production += fixture.native.extractor.extract(source, r'class bloodmage_talent_contracts\b') + ';\n'
    production += fixture.native.extractor.extract(fixture.src('Contracts'), r'enum FleshHook\b') + ';\n'
    production += 'namespace AscensionXoroth {' + fixture.methods('Contracts', ['ApplyContracts']) + '}\n'
    code = fixture.fixture().replace('/*PRODUCTION*/', production).replace('/*CASES*/', CASES)
    code = code.replace('struct SpellInfo {', 'struct SpellRangeEntry {uint32 ID = 0;}; '
                        'Store<SpellRangeEntry> sSpellRangeStore; struct SpellInfo { '
                        'SpellRangeEntry const* RangeEntry = nullptr; ')
    with tempfile.TemporaryDirectory(prefix='coa-secondary-decisions-') as directory:
        fixture.native.OUT = Path(directory)
        result = fixture.native.compile_run(code, 'decisions')
        assert result.returncode == 0, result.stdout + result.stderr
    raw = (args.spell_dbc.parent / 'SpellDuration.dbc').read_bytes()
    count, fields, width, _ = struct.unpack_from('<4I', raw, 4)
    assert (fields, width) == (4, 16)
    rows = {r[0]: r[1:] for r in struct.iter_unpack('<Iiii', raw[20:20 + count * width])}
    assert rows[27] == (3000, 0, 3000) and rows[32] == (6000, 0, 6000)
    print('PASS: Warpath 90% floor/3 seconds; Vampiric Pools leech preserved, native fear/6 seconds/same targets')


if __name__ == '__main__':
    main()
