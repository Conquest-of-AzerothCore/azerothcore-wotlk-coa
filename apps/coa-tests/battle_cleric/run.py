import os
from pathlib import Path
import re
import runpy
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent


def main():
    method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
    code = (HERE.parent / 'ranger_secondary/harness.cpp').read_text().split('// SOURCE')[0]
    code = code.replace('// ENUMS', method((ROOT / 'src/server/game/Spells/SpellInfo.h').read_text(),
                                         'enum SpellCustomAttributes') + ';')
    code = code.replace('struct SpellInfo', '''
constexpr uint32 CLASS_SUN_CLERIC = 27, SPELL_AURA_ANY = 0, SPELL_AURA_ADD_FLAT_MODIFIER = 107,
    SPELL_EFFECT_APPLY_AURA = 6, SPELLMOD_COOLDOWN = 11, TARGET_UNIT_CASTER = 1;
struct flag96
{
    uint32 a = 0, b = 0, c = 0;
    flag96(uint32 first = 0, uint32 second = 0, uint32 third = 0) : a(first), b(second), c(third) { }
};
struct SpellImplicitTargetInfo
{
    uint32 value = 0;
    SpellImplicitTargetInfo(uint32 target = 0) : value(target) { }
};
struct SpellEffectInfo
{
    uint32 Effect = 0, ApplyAuraName = 0, DieSides = 0, MiscValue = 0;
    int32 BasePoints = 0;
    flag96 SpellClassMask;
    SpellImplicitTargetInfo TargetA;
};
struct SpellInfo''', 1)
    code = code.replace('bool UseRangedAttackPowerForDamage', '''
    SpellEffectInfo Effects[3];
    bool rebuilt = false;
    void _InitializeExplicitTargetMask() { rebuilt = true; }
    bool UseRangedAttackPowerForDamage''')
    code = code.replace('uint8 stacks = 1;', '''uint8 stacks = 1;
    int32 maximum = 20000, duration = 20000;
    void SetMaxDuration(int32 value) { maximum = value; }
    void SetDuration(int32 value) { duration = value; }''')
    code = code.replace('Aura* GetAura(uint32 id, uint32 owner)', '''
    bool HasAura(uint32 id, uint32 owner) { return auras.contains({id, owner}); }
    Aura* GetAura(uint32 id, uint32 owner)''')
    code = code.replace('uint32 cls = 21;', 'uint32 cls = 27;')
    code = code.replace('Unit* fixtureCaster = nullptr;', '''uint32 fixtureId = 300347;
    uint32 GetId() const { return fixtureId; }
    Unit* fixtureCaster = nullptr;''')
    source = (ROOT / 'src/server/coa/AscensionSunClericBattleCleric.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M).replace(
        ': public AuraScript\n{', ': public AuraScript\n{\npublic:')
    code += source + r'''
int main()
{
    Player player, other; other.guid=2;
    aura_ascension_battle_cleric script;
    script.fixtureCaster=script.fixtureOwner=&player; assert(script.Load());
    script.Apply(nullptr,1); assert(!player.HasAura(562316,1));
    other.AddAura(680639,&player); script.Apply(nullptr,1); assert(!player.HasAura(562316,1));
    player.AddAura(680639,&player); script.Apply(nullptr,1);
    assert(player.GetAura(562316,1)->duration==-1 && player.GetAura(562316,1)->maximum==-1);
    assert(player.casts.empty()); // Applying the aura must not execute its legacy cooldown-reduction effect.
    script.Remove(nullptr,1); assert(!player.HasAura(562316,1));
    script.fixtureId=680639; script.Apply(nullptr,1); assert(!player.HasAura(562316,1));
    player.AddAura(300347,&player); script.Apply(nullptr,1); assert(player.HasAura(562316,1));
    other.AddAura(562316,&player); script.Remove(nullptr,1);
    assert(!player.HasAura(562316,1) && player.HasAura(562316,2));
    player.cls=1; assert(!script.Load()); player.cls=27;
    script.fixtureCaster=&other; assert(!script.Load());
    sun_cleric_battle_cleric_metadata metadata;
    SpellInfo info; info.Id=300347; info.SpellFamilyName=33;
    info.Effects[1].BasePoints=34; info.Effects[1].MiscValue=5;
    metadata.OnLoadSpellCustomAttr(&info);
    assert(info.rebuilt && info.Effects[0].Effect==6 && info.Effects[0].ApplyAuraName==107);
    assert(info.Effects[0].BasePoints==-240000 && info.Effects[0].MiscValue==11);
    assert(info.Effects[0].SpellClassMask.c==8388608 && info.Effects[0].TargetA.value==1);
    assert(info.Effects[1].BasePoints==34 && info.Effects[1].MiscValue==5);
    info.Id=562316; metadata.OnLoadSpellCustomAttr(&info);
    assert(info.AttributesCu & SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
    info.Id=300347; info.SpellFamilyName=32; info.rebuilt=false;
    metadata.OnLoadSpellCustomAttr(&info); assert(!info.rebuilt);
}
'''
    with tempfile.TemporaryDirectory(prefix='coa-battle-cleric-') as directory:
        out = Path(directory)
        cpp, exe = out / 'cleric.cpp', out / 'cleric.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    rows = {r[0]:r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in {300347,562316,680639}}
    assert rows[680639][29:31] == (300000,300000) and rows[680639][211] == 8388608
    assert rows[562316][95:97] == (108,108) and rows[562316][110:112] == (8,11)
    assert rows[562316][80] + rows[562316][74] == 50
    assert rows[562316][81] - 2**32 + rows[562316][75] == -100
    assert rows[300347][96] == 107 and rows[300347][111] == 5
    print('PASS: talent plus Paragon, owned helper lifetime, no repeated cooldown refund, 60s cooldown and native Gavel mods')


if __name__ == '__main__':
    main()
