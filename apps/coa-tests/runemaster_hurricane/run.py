from pathlib import Path
import runpy
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    helper = runpy.run_path(str(HERE.parent / 'runemaster_secondary/run.py'))
    code = helper['fixture']()
    code = code.replace('struct Unit;', '''
constexpr uint32 AURA_REMOVE_BY_DEATH=4, SPELL_AURA_PERIODIC_DUMMY=226,
    SPELLVALUE_BASE_POINT2=2, SPELL_ATTR5_EXTRA_INITIAL_PERIOD=512;
struct ObjectGuid
{
    uint64 value=0;
    ObjectGuid(uint64 raw=0):value(raw) {}
    operator uint32() const { return uint32(value); }
    uint64 GetRawValue() const { return value; }
};
template<class T> T CalculatePct(T value,int32 percent) { return T(value*percent/100); }
struct Unit;''', 1)
    code = code.replace('uint32 AttributesEx2=0,', 'uint32 AttributesEx5=512, AttributesEx2=0,')
    code = code.replace('uint8 stacks=1;', '''
    std::map<uint32,uint64> values;
    void SetScriptValue(uint32 key,uint64 value) { values[key]=value; }
    uint64 GetScriptValue(uint32 key) { return values[key]; }
    int32 duration=2000, maximum=2000;
    void SetMaxDuration(int32 value) { maximum=value; }
    void SetDuration(int32 value) { duration=value; }
    uint8 stacks=1;''')
    code = code.replace('Aura* aura=nullptr; Aura* GetBase()',
                        'uint32 mode=1; uint32 GetRemoveMode() const { return mode; } Aura* aura=nullptr; Aura* GetBase()')
    code = code.replace('appStore[index]={&aura};', 'appStore[index].aura=&aura;')
    code = code.replace('void SetUnitTarget(Unit* unit)', 'Unit* GetUnitTarget() const { return target; } void SetUnitTarget(Unit* unit)')
    code = code.replace('uint32 GetGUID() const { return guid; }', 'ObjectGuid GetGUID() const { return ObjectGuid(guid); }')
    code = code.replace('uint32 guid=1;', '''uint32 level=60, map=1;
    bool phase=true;
    uint32 GetLevel() const { return level; }
    uint32 GetMap() const { return map; }
    bool InSamePhase(Unit* unit) const { return phase && unit->phase; }
    bool IsValidAttackTarget(Unit* target) const { return target!=this && target->alive && !target->friendly; }
    uint32 guid=1;''')
    code = code.replace('struct Spell\n{', '''
std::map<uint32,Unit*> world;
namespace ObjectAccessor
{
    Unit* GetUnit(Unit&,ObjectGuid guid)
    { auto it=world.find(uint32(guid)); return it==world.end()?nullptr:it->second; }
}
struct Spell
{''')
    code = code.replace('Unit* caster=nullptr;\n    SpellInfo info;', '''SpellCastTargets m_targets;
    void SetSpellValue(uint32 key,int32 value) { values[key]=uint64(value); }
    Unit* caster=nullptr;
    SpellInfo info;''')
    code = code.replace('Hook DoCheckProc, OnEffectProc, AfterEffectRemove;', '''
    AuraApplication fixtureApplication;
    AuraApplication* GetTargetApplication() { return &fixtureApplication; }
    Unit* GetUnitOwner() const { return fixtureTarget; }
    virtual bool Load() { return true; }
    Hook OnEffectPeriodic, DoCheckProc, OnEffectProc, AfterEffectRemove;''')
    code += '''
struct SpellScript
{
    Spell* fixtureSpell=nullptr;
    Unit* fixtureHit=nullptr;
    int32 fixtureDamage=100;
    Hook BeforeCast, OnHit;
    virtual bool Load() { return true; }
    virtual void Register() {}
    Spell* GetSpell() { return fixtureSpell; }
    SpellInfo const* GetSpellInfo() const { return &fixtureSpell->info; }
    Unit* GetCaster() const { return fixtureSpell->caster; }
    Unit* GetHitUnit() const { return fixtureHit; }
    int32 GetHitDamage() const { return fixtureDamage; }
    void SetHitDamage(int32 amount) { fixtureDamage=amount; }
};
#define PrepareSpellScript(name)
#define SpellCastFn(...) 0
#define SpellHitFn(...) 0
#define AuraEffectPeriodicFn(...) 0
'''
    helper['compile_case'](code, 'AscensionRunemasterHurricane.cpp', r'''
int main()
{
    Player player, opponent; opponent.guid=4;
    Unit enemy; enemy.guid=3; world[3]=&enemy;
    runemaster_hurricane_cast cast;
    Spell spell; spell.caster=&player; spell.info.Id=645435; spell.m_targets.target=&enemy;
    aura_ascension_runemaster_hurricane channel; channel.fixtureCaster=channel.fixtureTarget=&player;
    assert(channel.Load());
    for (uint32 ticks : {4u,6u})
    {
        player.casts.clear(); auto* aura=player.AddAura(645435,&player);
        cast.OnSpellCast(&spell,&player,&spell.info,false);
        assert(player.GetAura(645440,1)->duration==-1 && player.casts.size()==1);
        channel.fixtureAura=*aura;
        for (uint32 i=0;i<ticks;++i) channel.Tick(nullptr);
        assert(player.casts.size()==ticks+1);
        for (auto const& hit : player.casts) assert(hit.id==645437 && hit.target==&enemy);
        player.AddAura(705565,&player); channel.End(nullptr,1);
        assert(!player.HasAura(645440,1) && player.casts.back().id==500469);
    }
    for (int guard=0;guard<5;++guard)
    {
        player.casts.clear(); channel.fixtureAura.removed=false;
        enemy.alive=guard!=0; enemy.inWorld=guard!=1; enemy.phase=guard!=2;
        enemy.map=guard==3?2:1; enemy.friendly=guard==4;
        channel.Tick(nullptr); assert(channel.fixtureAura.removed && player.casts.empty());
    }
    channel.fixtureApplication.mode=4; channel.End(nullptr,1); assert(player.casts.empty());
    spell_ascension_hurricane_damage damage; damage.fixtureSpell=&spell;
    spell.info.Effects[2].BasePoints=151;
    for (uint32 level=1;level<=80;++level)
    {
        player.level=level; damage.Scale();
        double scale=.0267291844060354+.0048541098014737*level+.0001859597762293*level*level;
        assert(spell.values[2]==uint64(152*scale));
    }
    damage.fixtureHit=&opponent; damage.fixtureDamage=301; damage.Hit(); assert(damage.fixtureDamage==240);
    damage.fixtureHit=&enemy; damage.fixtureDamage=301; damage.Hit(); assert(damage.fixtureDamage==301);
    runemaster_hurricane_metadata metadata; SpellInfo info; info.Id=645435; info.SpellFamilyName=38;
    metadata.OnLoadSpellCustomAttr(&info); assert(!(info.AttributesEx5&512));
    assert(info.AttributesCu&SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
}
''')
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {645435, 645437, 645440, 706672, 500469}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[645435][40] == 39 and rows[645435][98] == 500 and rows[645435][9] & 512
    assert rows[706672][80] + rows[706672][74] == 1000 and rows[706672][110] == 1
    assert rows[645437][73] == 31 and rows[645437][232] == 182
    assert rows[645440][96] == 49 and rows[645440][81] + rows[645440][75] == 100
    assert rows[500469][95] == 275 and rows[500469][124] == 67108864
    print('PASS: 5/7 Hurricane strikes, target/death/phase cleanup, Waveforged, level 1-80 scaling and PvP damage')


if __name__ == '__main__':
    main()
