CLI_DESCRIPTION = """Compile the actual Brand damage callback against creature-type and spell-family boundaries."""
import argparse
import importlib.util
from pathlib import Path
import re
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--before', help='Use older ability callbacks as a negative control')
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location('witch_fixture', ROOT.parent / 'tools/Test-WitchHunterCompletion.py')
    fixture = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fixture)
    read = fixture.read
    def read_fixture(path):
        code = read(path)
        if path.name == 'WitchHunterCompletionHarness.cpp':
            code = code.replace('struct Unit {', 'struct Unit { uint32 creatureMask=0; '
                                'uint32 GetCreatureTypeMask() const { return creatureMask; }')
        return code
    fixture.read = read_fixture
    path = 'src/server/coa/AscensionWitchHunterAbilities.cpp'
    source = (git_source(['git', 'show', f'{args.before}:{path}'], cwd=ROOT).decode()
              if args.before else (ROOT / path).read_text())
    shared = (ROOT / 'src/server/shared/SharedDefines.h').read_text()
    code = fixture.common() + '\n' + fixture.extract(shared, r'enum CreatureType\b') + ';\n'
    code += re.search(r'uint32 const CREATURE_TYPEMASK_DEMON_OR_UNDEAD[^;]+;', shared)[0] + '\n'
    code += fixture.extract(shared, r'enum SpellMissInfo\b') + ';\n'
    code += fixture.extract(source, r'enum WitchHunterCastSpells\b') + ';\n'
    header = (ROOT / 'src/server/coa/AscensionWitchHunterCompletion.h').read_text()
    code += fixture.extract(header, r'enum WitchHunterSharedSpells\b') + ';\n'
    code += 'struct TargetInfo { int32 damage=1000, damageBeforeTakenMods=1200; '
    code += 'uint8 missCondition=SPELL_MISS_NONE; };\nstruct Hits {\n'
    code += fixture.extract(source, r'void OnSpellCalculatedTarget\([^)]*\) override').replace(' override', '')
    code += '\n};\n'
    cases = r'''
int main()
{
    Player caster; Unit target; target.guid=2;
    SpellInfo spellInfo; spellInfo.Id=807683;
    Spell cast; cast.caster=&caster; cast.info=&spellInfo; cast.triggered=true;
    Hits hook;
    for (uint32 type=1; type<=15; ++type)
    {
        target.creatureMask=1u<<(type-1); TargetInfo hit;
        hook.OnSpellCalculatedTarget(&cast,&target,hit);
        int32 factor=(type==CREATURE_TYPE_DEMON || type==CREATURE_TYPE_UNDEAD)?2:1;
        assert(hit.damage==1000*factor && hit.damageBeforeTakenMods==1200*factor);
    }
    target.creatureMask=CREATURE_TYPEMASK_DEMON_OR_UNDEAD;
    for (uint32 id : {807683u,807682u,807705u,680483u,802850u})
        for (uint32 cls : {15u,20u}) for (uint32 family : {21u,22u})
        {
            spellInfo.Id=id; spellInfo.SpellFamilyName=family; caster.cls=cls;
            TargetInfo hit; hook.OnSpellCalculatedTarget(&cast,&target,hit);
            int32 factor=id==807683 && cls==15 && family==21?2:1;
            assert(hit.damage==1000*factor && hit.damageBeforeTakenMods==1200*factor);
        }
    spellInfo.Id=807683; spellInfo.SpellFamilyName=21; caster.cls=15;
    TargetInfo miss; miss.missCondition=SPELL_MISS_IMMUNE;
    hook.OnSpellCalculatedTarget(&cast,&target,miss); assert(miss.damage==1000);
    TargetInfo zero; zero.damage=0; hook.OnSpellCalculatedTarget(&cast,&target,zero); assert(zero.damage==0);
    TargetInfo self; caster.creatureMask=CREATURE_TYPEMASK_DEMON_OR_UNDEAD;
    hook.OnSpellCalculatedTarget(&cast,&caster,self); assert(self.damage==1000);
}
'''
    with tempfile.TemporaryDirectory(prefix='coa-brand-') as directory:
        fixture.native.OUT = Path(directory)
        fixture.Tests().run_cpp('brand-creature-bonus', code, cases)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20 + count * 936])
            if r[0] in {570757, 807682, *range(807705, 807711)}}
    assert rows[570757][80] + rows[570757][74] == 100 and rows[570757][113] == 36
    for sid in (807682, *range(807705, 807711)):
        assert rows[sid][116] == 807683
    print('PASS: Brand ranks, Undead/Demon bonus, class/family/spell boundaries and miss/self exclusions')


if __name__ == '__main__':
    main()
