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


def fixture():
    method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
    code = (HERE.parent / 'reaper_secondary/harness.cpp').read_text().split('// SOURCE')[0]
    code = code.replace('// ENUMS', '#include "%s"\n%s;' % (
        (ROOT / 'src/server/coa/AscensionTalentReplacementData.h').as_posix(),
        method((ROOT / 'src/server/game/Spells/SpellInfo.h').read_text(), 'enum SpellCustomAttributes')))
    code = code.replace('struct Unit;', '''
using AuraType=uint32;
constexpr uint32 CLASS_SPIRIT_MAGE=32, EFFECT_1=1, EFFECT_2=2, UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE=7,
    BASE_ATTACK=0, OFF_ATTACK=1, SPELLVALUE_MELEE_ATTACK_TYPE=10, SPELL_DIRECT_DAMAGE=1,
    SPELL_SCHOOL_MASK_MAGIC=126, SPELL_ATTR2_CANT_CRIT=1,
    SPELL_ATTR3_IGNORE_CASTER_MODIFIERS=2, SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS=4,
    DOT=2, AURA_REMOVE_BY_EXPIRE=3, SPELL_AURA_PERIODIC_DAMAGE=3;
template<class T> void AddPct(T& value,int32 percent) { value+=value*percent/100; }
bool fixtureRoll=true;
uint32 lastChance=0;
bool roll_chance_i(uint32 chance) { lastChance=chance; return fixtureRoll; }
struct Unit;''', 1)
    code = code.replace('struct Effect\n', '''uint32 AttributesEx2=0, AttributesEx3=0, AttributesEx4=0, ProcChance=100;
    bool AscensionInheritsResolvedAmount=false;
    struct Effect
''')
    code = code.replace('int32 value=0;', 'int32 value=0, BasePoints=0; float BonusMultiplier=1.0f;')
    code = code.replace('uint32 ApplyAuraName=42;', '''uint32 ApplyAuraName=42, TriggerSpell=0;
        bool IsAura(uint32 type) const { return ApplyAuraName==type; }''')
    code = code.replace('uint8 stacks=1;', '''bool removed=false; void Remove() { removed=true; }
    int32 duration=3000;
    int32 GetDuration() const { return duration; }
    void SetDuration(int32 value) { duration=value; }
    bool ModStackAmount(int32 num) { stacks=uint8(stacks+num); duration=3000; return false; }
    uint8 stacks=1;''')
    code = code.replace('struct AuraEffect {};', '''struct AuraEffect
    {
        int32 amount=5;
        SpellInfo spellInfo;
        int32 GetAmount() const { return amount; }
        SpellInfo const* GetSpellInfo() const { return &spellInfo; }
        uint32 GetEffIndex() const { return 0; }
    };''')
    code = code.replace('struct Unit\n{', '''
struct SpellCastTargets { Unit* target=nullptr; void SetUnitTarget(Unit* unit) { target=unit; } };
struct CustomSpellValues
{
    std::map<uint32,int32> mods;
    void AddSpellMod(uint32 key,int32 value) { mods[key]=value; }
};
struct Unit
{''')
    code = code.replace('uint32 guid=1;', '''float attackPower=1000;
    float GetTotalAttackPowerValue(uint32) const { return attackPower; }
    std::map<uint32,AuraApplication> appStore;
    std::map<uint32,AuraApplication*> applications;
    auto const& GetAppliedAuras()
    {
        appStore.clear(); applications.clear(); uint32 index=0;
        for (auto& [key,aura] : auras) { appStore[index]={&aura}; applications[index]=&appStore[index]; ++index; }
        return applications;
    }
    uint32 guid=1;''')
    code = code.replace('struct Cast { uint32 id; Unit* target; int32 amount; };',
                        'struct Cast { uint32 id; Unit* target; int32 amount; int32 hand=0; };')
    code = code.replace('if (id==807416)', 'if (id==807416 || id==500468)')
    code = code.replace('std::min(uint8(5),uint8(aura->stacks+1))',
                        'std::min(uint8(id==500468?3:5),uint8(aura->stacks+1))')
    code = code.replace('void CastCustomSpell(', '''void CastSpell(SpellCastTargets const& targets,SpellInfo const* info,
        CustomSpellValues const* values,bool triggered)
    {
        assert(triggered); casts.push_back({info->Id,targets.target,values->mods.at(0),values->mods.at(10)});
    }
    void CastCustomSpell(''')
    code = code.replace('int32 amount,Unit* target,bool triggered)',
                        'int32 amount,Unit* target,bool triggered,void* = nullptr,AuraEffect const* = nullptr)')
    code = code.replace('uint32 cls=30,', '''std::map<uint32,int> spells;
    std::vector<uint32> restored, restoredCounts, cleared;
    bool offhand=true;
    auto const& GetSpellMap() const { return spells; }
    bool HasActiveSpell(uint32 id) const { return spells.contains(id); }
    AuraEffect const* GetAuraEffect(uint32,uint32,uint32) const { return nullptr; }
    void RestoreSpellCharge(uint32 id,uint32 count) { restored.push_back(id); restoredCounts.push_back(count); }
    void RemoveSpellCooldown(uint32 id,bool update) { assert(update); cleared.push_back(id); }
    void* GetWeaponForAttack(uint32 hand,bool usable) { assert(hand==1 && usable); return offhand?this:nullptr; }
    uint32 cls=32,''')
    code = code.replace('uint32 amount=100, school=1;',
                        'uint32 amount=100, school=1, type=1; uint32 GetDamageType() const { return type; }')
    code = code.replace('bool prevented=false;', '''Aura fixtureAura; Aura* GetAura() { return &fixtureAura; }
    SpellInfo fixtureSpellInfo;
    SpellInfo const* GetSpellInfo() const { return &fixtureSpellInfo; }
    virtual bool Validate(SpellInfo const*) { return true; }
    static bool ValidateSpellInfo(std::initializer_list<uint32> ids)
    {
        for (uint32 id : ids) if (!sSpellMgr->GetSpellInfo(id)) return false;
        return true;
    }
    struct Application { uint32 mode=AURA_REMOVE_BY_EXPIRE; uint32 GetRemoveMode() const { return mode; } } fixtureApplication;
    Application const* GetTargetApplication() const { return &fixtureApplication; }
    uint8 GetStackAmount() const { return fixtureAura.stacks; }
    bool prevented=false;''')
    code = code.replace('virtual void OnAuraApply(Unit*,Aura*) {}', '''
    virtual void ModifySpellEffectBaseValue(Unit const*,SpellInfo const*,uint8,float&) {}
    virtual void OnAuraApply(Unit*,Aura*) {}''')
    return code


def compile_case(code, source_name, cases):
    source = (ROOT / 'src/server/coa' / source_name).read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    for base in ['AuraScript', 'SpellScript']:
        source = source.replace(f': public {base}\n{{', f': public {base}\n{{\npublic:')
    with tempfile.TemporaryDirectory(prefix='coa-runemaster-secondary-') as directory:
        out = Path(directory)
        cpp, exe = out / 'runemaster.cpp', out / 'runemaster.exe'
        cpp.write_text(code + source + cases, encoding='utf-8')
        compiler = Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe'
        subprocess.run([str(compiler), '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)


def main():
    compile_case(fixture(), 'AscensionRunemasterSecondary.cpp', r'''
int main()
{
    Player player, other; other.guid=2;
    Unit enemy; enemy.guid=3;
    player.spells={{707148,1},{502632,1}};
    manager.roots[707148]=707141; manager.roots[502632]=801087;
    manager.roots[803749]=801106; manager.roots[807839]=801107;
    manager.rows[802661].ProcChance=20;
    manager.rows[801511].ProcChance=100;
    manager.rows[500462].Effects[0].value=50;
    manager.rows[712298].Id=712298;
    manager.rows[802645].Effects[2].value=20;
    runemaster_secondary_auras auras;
    auto* passive=player.AddAura(804561,&player); auras.OnAuraApply(&player,passive);
    assert(!player.HasAura(807377,1));
    auto* tattoo=player.AddAura(803749,&player); auras.OnAuraApply(&player,tattoo);
    assert(player.HasAura(807377,1) && !player.HasAura(807378,1));
    Aura removed=*tattoo; player.RemoveAurasDueToSpell(803749,1); AuraApplication application{&removed};
    auras.OnAuraRemove(&player,&application,1); assert(!player.HasAura(807377,1));
    tattoo=player.AddAura(807839,&player); auras.OnAuraApply(&player,tattoo); assert(player.HasAura(807378,1));
    SpellInfo mana; mana.Id=500466; float value=100;
    auras.ModifySpellEffectBaseValue(&player,&mana,0,value); assert(value==480);
    player.RemoveAurasDueToSpell(807839,1); value=100;
    auras.ModifySpellEffectBaseValue(&player,&mana,0,value); assert(value==400);
    player.AddAura(92154,&player); player.AddAura(801511,&player);
    runemaster_secondary_casts casts;
    Spell spell; spell.caster=&player; spell.info.Id=707148;
    for (int i=0;i<6;++i) casts.OnSpellCast(&spell,&player,&spell.info,false);
    assert(std::count_if(player.casts.begin(),player.casts.end(),[](auto const& cast){return cast.id==500466;})==2);
    assert(!player.HasAura(500468,1)); assert(lastChance==20 && player.cleared.size()==6);
    spell.info.Id=500287; casts.OnSpellCast(&spell,&player,&spell.info,false); assert(lastChance==100);
    spell.info.Id=502632; casts.OnSpellCast(&spell,&player,&spell.info,false);
    assert(player.restored.back()==707148 && !player.HasAura(801512,1));
    spell.info.Id=800732; casts.OnSpellCast(&spell,&player,&spell.info,false); assert(player.restored.size()==2);
    assert(player.restoredCounts==std::vector<uint32>({1,1}));
    player.AddAura(806698,&player);
    auto const withMagic=player.restored.size();
    casts.OnSpellCast(&spell,&player,&spell.info,false);
    assert(player.restored.size()==withMagic+1 && player.restored.back()==707148 &&
        player.restoredCounts.back()==3);
    for (uint32 blast : {712668u,712858u,713002u,712404u,805794u})
    {
        auto const before=player.restored.size();
        spell.info.Id=blast; casts.OnSpellCast(&spell,&player,&spell.info,false);
        assert(player.restored.size()==before+1 && player.restored.back()==707148 &&
            player.restoredCounts.back()==3);
    }
    spell.info.Id=502632; casts.OnSpellCast(&spell,&player,&spell.info,false);
    assert(player.restoredCounts.back()==1);
    player.RemoveAurasDueToSpell(806698,1); player.restored.resize(2); player.restoredCounts.resize(2);
    auto const withoutMagic=player.restored.size();
    spell.info.Id=712668; casts.OnSpellCast(&spell,&player,&spell.info,false);
    assert(player.restored.size()==withoutMagic+1 && player.restoredCounts.back()==1);
    player.AddAura(92153,&player); spell.info.Id=707148; player.casts.clear();
    casts.OnSpellHitResult(&spell,&enemy,0,301,0,false);
    assert(player.casts.size()==1 && player.casts.back().id==712298 && player.casts.back().amount==150);
    assert(player.casts.back().hand==1);
    casts.OnSpellHitResult(&spell,&enemy,0,301,0,false); assert(player.casts.size()==1);
    for (int guard=0;guard<4;++guard)
    {
        spell.values.clear(); player.offhand=guard!=0; spell.triggered=guard==1;
        casts.OnSpellHitResult(&spell,&enemy,guard==2?1:0,guard==3?0:300,0,false);
        assert(player.casts.size()==1);
    }
    aura_ascension_arcane_palm_sigil sigil; sigil.fixtureCaster=sigil.fixtureTarget=&player;
    DamageInfo damage; damage.amount=301; damage.school=64;
    ProcEventInfo event{&player,&enemy,&damage}; AuraEffect amount;
    assert(sigil.Check(event)); sigil.Proc(&amount,event); assert(!sigil.fixtureAura.removed);
    assert(player.casts[player.casts.size()-2].id==807819 && player.casts[player.casts.size()-2].amount==15);
    assert(player.casts.back().id==808020);
    damage.type=2; assert(!sigil.Check(event)); damage.type=1;
    damage.school=1; assert(!sigil.Check(event)); damage.school=64;
    event.actor=&other; assert(!sigil.Check(event));
    aura_ascension_damage_palm_sigil copied; copied.fixtureCaster=copied.fixtureTarget=&player;
    copied.fixtureSpellInfo.Effects[0].TriggerSpell=807012;
    event.actor=&player; damage.amount=301; damage.school=64; damage.type=1;
    amount.amount=120; amount.spellInfo.Effects[0].TriggerSpell=807012;
    assert(copied.Check(event)); copied.Proc(&amount,event);
    assert(copied.prevented && !copied.fixtureAura.removed);
    assert(player.casts.back().id==807012 && player.casts.back().amount==361);
    damage.school=1; assert(copied.Check(event)); damage.school=64;
    copied.fixtureSpellInfo.Effects[0].TriggerSpell=807825;
    amount.amount=30; amount.spellInfo.Effects[0].TriggerSpell=807825; copied.Proc(&amount,event);
    assert(player.casts.back().id==807825 && player.casts.back().amount==90);
    copied.fixtureSpellInfo.Effects[0].TriggerSpell=807818;
    amount.amount=50; amount.spellInfo.Effects[0].TriggerSpell=807818; copied.Proc(&amount,event);
    assert(player.casts.back().id==807818 && player.casts.back().amount==150);
    damage.type=2; assert(!copied.Check(event)); damage.type=1;
    damage.school=1; assert(!copied.Check(event)); damage.school=64;
    event.actor=&other; assert(!copied.Check(event));
    amount.amount=5;
    aura_ascension_runemaster_fire_engraving engraving; engraving.fixtureCaster=engraving.fixtureTarget=&player;
    damage.type=0; event.actor=&player; player.casts.clear();
    assert(engraving.Check(event)); engraving.Proc(&amount,event);
    assert(engraving.prevented && player.casts.size()==1 && player.casts.back().id==653210);
    auto* brand=player.AddAura(653210,&enemy); brand->duration=1200; player.casts.clear();
    engraving.Proc(&amount,event); assert(player.casts.empty() && brand->stacks==2 && brand->duration==1200);
    damage.type=2; assert(!engraving.Check(event)); damage.type=1;
    event.actor=&other; assert(!engraving.Check(event)); event.actor=&player;
    runemaster_secondary_metadata metadata; SpellInfo info; info.SpellFamilyName=38; info.Id=712298;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.AscensionInheritsResolvedAmount);
}
''')
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {500462, 500466, 500468, 802645, 802661, 801511, 807377, 807378, 807819, 808020, 653210, 653211, 653212}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[500462][80] + rows[500462][74] == 50 and rows[500468][49] == 3
    assert rows[802661][35] == 20 and rows[801511][35] == 100
    assert rows[802645][82] + rows[802645][76] == 20
    assert rows[807377][110] == 15 and rows[807378][110] == 14
    assert rows[807819][95] == 3 and rows[807819][98] == 3000 and rows[808020][95] == 27
    assert rows[653211][35] == 30 and rows[653211][95] == 42 and rows[653211][116] == 653210
    assert rows[653210][95] == 3 and rows[653212][71] == 2
    print('PASS: offhand copies, charge restoration, third-cast mana, Water scaling, Spellfire consumption, tattoo ownership, Sigil, Fire Engraving')


if __name__ == '__main__':
    main()
