import os
from pathlib import Path
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
    code = (HERE.parent / 'reaper_secondary/harness.cpp').read_text().split('// SOURCE')[0]
    code = code.replace('// ENUMS', method((ROOT / 'src/server/game/Spells/SpellInfo.h').read_text(),
                                         'enum SpellCustomAttributes') + ';')
    code = code.replace('struct Unit;', '''
using AuraType=uint32;
using SpellMissInfo=uint32;
constexpr uint32 CLASS_WILDWALKER=31, EFFECT_1=1, AURA_REMOVE_BY_EXPIRE=3,
    PROC_HIT_CRITICAL=2, SPELL_SCHOOL_MASK_NATURE=8, SPELL_ATTR2_CANT_CRIT=1,
    SPELL_ATTR3_IGNORE_CASTER_MODIFIERS=2, SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS=4,
    SPELL_AURA_MOD_MAX_AFFECTED_TARGETS=277, AURA_INTERRUPT_FLAG_TAKE_DAMAGE=2,
    TARGET_UNIT_PET=5, TARGET_UNIT_CASTER=1;
struct SpellImplicitTargetInfo
{
    uint32 target=0;
    explicit SpellImplicitTargetInfo(uint32 value=0) : target(value) {}
    uint32 GetTarget() const { return target; }
};
struct Unit;''', 1)
    code = code.replace('struct Effect\n', '''uint32 AttributesEx2=0, AttributesEx3=0, AttributesEx4=0,
        AuraInterruptFlags=0, ProcCharges=0;
    bool AscensionInheritsResolvedAmount=false;
    struct Effect
''')
    code = code.replace('int32 value=0;', 'int32 value=0; float BonusMultiplier=1.0f;')
    code = code.replace('uint32 ApplyAuraName=42;', '''uint32 ApplyAuraName=42;
        SpellImplicitTargetInfo TargetA, TargetB;
        bool IsAura() const { return true; }''')
    code = code.replace('} Effects[3];', '} Effects[3];\n    void _InitializeExplicitTargetMask() {}')
    code = code.replace('struct SpellMgr', 'using SpellEffectInfo=SpellInfo::Effect;\nstruct SpellMgr', 1)
    code = code.replace('struct AuraEffect {};',
                        'struct AuraEffect { int32 amount=20; int32 GetAmount() const { return amount; } };')
    code = code.replace('uint32 guid=1;', '''Unit* victim=nullptr;
    bool threat=true;
    bool CanHaveThreatList() const { return threat; }
    Unit* GetVictim() const { return victim; }
    uint32 guid=1;''')
    code = code.replace('uint32 cls=30,', 'uint32 cls=31,')
    code = code.replace('Unit* actor=nullptr;', 'uint32 hit=2; uint32 GetHitMask() const { return hit; }\n    Unit* actor=nullptr;')
    code += '''
struct SpellScript
{
    Unit* fixtureCaster=nullptr; Unit* fixtureHit=nullptr;
    Hook BeforeHit, AfterHit;
    virtual bool Load() { return true; }
    virtual void Register() {}
    Unit* GetCaster() const { return fixtureCaster; }
    Unit* GetHitUnit() const { return fixtureHit; }
};
#define PrepareSpellScript(name)
#define SpellHitFn(...) 0
#define BeforeSpellHitFn(...) 0
'''
    full_source = (ROOT / 'src/server/coa/AscensionPrimalistSecondary.cpp').read_text()
    declarations = ['enum PrimalistSecondarySpells', 'class primalist_secondary_auras',
                    'class aura_ascension_volcanic_blast', 'class aura_ascension_hammer_of_life',
                    'class primalist_volcanic_targets', 'class spell_ascension_gaze_of_theradras',
                    'class primalist_secondary_metadata']
    source = '\n'.join(method(full_source, declaration) + ';' for declaration in declarations)
    for base in ['AuraScript', 'SpellScript']:
        source = source.replace(f': public {base}\n{{', f': public {base}\n{{\npublic:')
    code += source + r'''
int main()
{
    Player player, other; other.guid=2;
    Unit enemy; enemy.guid=3;
    primalist_secondary_auras events;
    Aura* form=player.AddAura(805105,&player); events.OnAuraApply(&player,form);
    assert(player.HasAura(504369,1));
    other.AddAura(504369,&player); AuraApplication removed{form};
    events.OnAuraRemove(&player,&removed,1);
    assert(!player.HasAura(504369,1) && player.HasAura(504369,2));
    player.AddAura(561037,&player); removed.aura=player.AddAura(806143,&player);
    for (uint32 mode : {1u,2u,3u,4u})
    {
        player.casts.clear(); events.OnAuraRemove(&player,&removed,mode);
        assert(player.casts.size()==(mode==3?1u:0u));
    }
    player.casts.clear(); player.alive=false; events.OnAuraRemove(&player,&removed,3);
    assert(player.casts.empty()); player.alive=true;
    aura_ascension_volcanic_blast blast; blast.fixtureCaster=blast.fixtureTarget=&player;
    DamageInfo damage; damage.amount=501; ProcEventInfo event;
    event.actor=&player; event.target=&enemy; event.damage=&damage;
    AuraEffect effect;
    for (uint32 school : {1u,8u})
        for (int32 percent : {20,40})
        {
            damage.school=school; effect.amount=percent; assert(blast.Check(event));
            blast.Proc(&effect,event);
            assert(player.casts.back().id==681353 && player.casts.back().amount==501*percent/100);
        }
    damage.school=4; assert(!blast.Check(event)); damage.school=1;
    event.hit=1; assert(!blast.Check(event)); event.hit=2;
    event.actor=&other; assert(!blast.Check(event)); event.actor=&player;
    damage.amount=0; assert(!blast.Check(event));
    primalist_volcanic_targets targets; player.AddAura(560145,&player);
    for (uint32 count=0;count<=25;++count)
    {
        Spell spell; spell.caster=&player; spell.info.Id=681353; spell.triggered=true;
        player.casts.clear();
        for (uint32 i=0;i<count;++i) targets.OnSpellHitResult(&spell,&enemy,0,100,0,false);
        assert(player.casts.size()==(count>=5?1u:0u));
        targets.OnSpellHitResult(&spell,&enemy,1,100,0,false); // Misses never count.
        assert(spell.GetScriptValue(560146)==count);
    }
    spell_ascension_gaze_of_theradras gaze; gaze.fixtureCaster=&player; gaze.fixtureHit=&enemy;
    assert(gaze.Load()); player.casts.clear();
    gaze.Before(0); gaze.After(); assert(player.casts.empty()); // Immune taunt did not apply.
    player.AddAura(805919,&enemy); gaze.Before(1); gaze.After(); assert(player.casts.empty());
    gaze.Before(0); gaze.After();
    assert(player.casts.size()==1 && player.casts.back().id==572908);
    enemy.victim=&player; gaze.Before(0); gaze.After(); assert(player.casts.size()==1);
    enemy.victim=&other; enemy.threat=false; gaze.Before(0); gaze.After(); assert(player.casts.size()==1);
    primalist_secondary_metadata metadata; SpellInfo info; info.SpellFamilyName=37; info.Id=681353;
    metadata.OnLoadSpellCustomAttr(&info);
    assert(info.AscensionInheritsResolvedAmount && info.Effects[0].BonusMultiplier==0);
    info.Id=560146; metadata.OnLoadSpellCustomAttr(&info); assert(info.Effects[1].ApplyAuraName==277);
    info.Id=706200; metadata.OnLoadSpellCustomAttr(&info); assert(info.AuraInterruptFlags&2);
    info.Id=572908; metadata.OnLoadSpellCustomAttr(&info); assert(info.ProcCharges==1);
}
'''
    with tempfile.TemporaryDirectory(prefix='coa-primalist-secondary-') as directory:
        out = Path(directory)
        cpp, exe = out / 'primalist.cpp', out / 'primalist.exe'
        cpp.write_text(code, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {560146, 804433, 560171, 681353, 680451, 681480, 572908, 706200}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[560146][49] == 5 and rows[560146][112] == 17
    assert rows[804433][104] == rows[560171][104] == 5
    assert rows[681353][86] == 53 and rows[681353][89] == 16
    assert rows[680451][116] == rows[681480][116] == 681353
    assert rows[572908][95] == 192 and rows[572908][80] - 2**32 + rows[572908][74] == -50
    assert rows[706200][95] == 5
    print('PASS: owned Ancient slow, full Embrace expiry, critical Volcanic copies, 0-25 targets, taunt immunity/current victim')


if __name__ == '__main__':
    main()
