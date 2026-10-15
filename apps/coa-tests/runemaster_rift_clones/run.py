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
    code = '#include <cmath>\n#include <memory>\n#include <chrono>\n' + code
    code = code.replace('struct Unit;', '''
constexpr uint32 TEMPSUMMON_TIMED_DESPAWN=1, MOVE_RUN=0, REACT_PASSIVE=0, FORCED_MOVEMENT_RUN=1;
constexpr double M_PI=3.14159265358979323846;
using Milliseconds=std::chrono::milliseconds;
struct Creature; struct TempSummon;
struct SpellRadiusEntry { float RadiusMin=5.0f; };
struct RadiusStore
{
    SpellRadiusEntry row;
    SpellRadiusEntry const* LookupEntry(uint32 id) const { assert(id==8); return &row; }
} sSpellRadiusStore;
struct Position { float x=5.0f; };
float frand(float first,float last) { assert(first==0 && last>6); return 1.0f; }
struct Unit;''', 1)
    code = code.replace('uint32 Id=0,', 'int32 duration=5000; int32 GetDuration() const { return duration; }\n    uint32 Id=0,')
    code = code.replace('float BonusMultiplier=1.0f;',
                        'float BonusMultiplier=1.0f; SpellRadiusEntry const* RadiusEntry=nullptr;')
    code = code.replace('virtual Player* ToPlayer()', 'virtual Creature const* ToCreature() const { return nullptr; }\n    virtual Player* ToPlayer()')
    code = code.replace('uint32 guid=1;', '''uint32 level=60, faction=35, map=1;
    bool phase=true;
    Position point;
    Position GetPosition() const { return point; }
    uint32 GetLevel() const { return level; }
    uint32 GetFaction() const { return faction; }
    bool IsInMap(Unit* unit) const { return map==unit->map; }
    bool InSamePhase(Unit* unit) const { return phase && unit->phase; }
    uint32 guid=1;''')
    code = code.replace('uint32 cls=32,', '''
    TempSummon* SummonCreature(uint32,Position const&,uint32,uint32);
    uint32 cls=32,''')
    code += '''
using WorldObject=Unit;
std::map<uint32,Unit*> world;
struct EventMap
{
    uint32 pending=0;
    int64_t remaining=0;
    void ScheduleEvent(uint32 event,Milliseconds delay) { pending=event; remaining=delay.count(); }
    void Update(uint32 diff) { remaining-=diff; }
    uint32 ExecuteEvent() { if (remaining>0) return 0; auto value=pending; pending=0; return value; }
};
struct MotionMaster
{
    Position destination;
    void MovePoint(uint32 id,Position const& point,uint32 mode)
    { assert(id==1 && mode==1); destination=point; }
};
struct Creature : Unit
{
    uint32 owner=0, entry=840004, lifetime=0;
    MotionMaster motion;
    Creature const* ToCreature() const override { return this; }
    uint32 GetEntry() const { return entry; }
    Unit* GetOwner() const { auto it=world.find(owner); return it==world.end()?nullptr:it->second; }
    void SetOwnerGUID(uint32 id) { owner=id; }
    void SetLevel(uint32 value) { level=value; }
    void SetFaction(uint32 value) { faction=value; }
    void SetReactState(uint32 value) { assert(value==0); }
    void DespawnOrUnsummon() { inWorld=false; }
    float GetSpeed(uint32 type) const { assert(type==0); return auras.contains({707465,owner})?4.9f:7.0f; }
    Position GetFirstCollisionPosition(float distance,float angle) const { assert(angle==1); return {point.x+distance}; }
    MotionMaster* GetMotionMaster() { return &motion; }
};
struct TempSummon : Creature {};
struct ScriptedAI
{
    Creature* me;
    explicit ScriptedAI(Creature* unit):me(unit) {}
    virtual ~ScriptedAI()=default;
    virtual void IsSummonedBy(WorldObject*) {}
    virtual void UpdateAI(uint32) {}
};
#define RegisterCreatureAI(name)
'''
    helper['compile_case'](code, 'AscensionRunemasterRiftClones.cpp', r'''
std::vector<std::unique_ptr<TempSummon>> summons;
std::vector<std::unique_ptr<npc_ascension_rift_clone>> brains;
TempSummon* Player::SummonCreature(uint32 entry,Position const& spawnPosition,uint32 type,uint32 duration)
{
    assert(entry==840004 && type==1 && duration==5000);
    auto summon=std::make_unique<TempSummon>(); summon->point=spawnPosition; summon->lifetime=duration;
    auto brain=std::make_unique<npc_ascension_rift_clone>(summon.get()); brain->IsSummonedBy(this);
    auto* result=summon.get(); summons.push_back(std::move(summon)); brains.push_back(std::move(brain)); return result;
}
int main()
{
    Player player; world[1]=&player;
    manager.rows[707464].Effects[0].value=10;
    Spell spell; spell.caster=&player; spell.info.Id=500671;
    runemaster_rift_clone_cast cast;
    cast.OnSpellCast(&spell,&player,&spell.info,false); assert(summons.empty());
    player.AddAura(707463,&player); cast.OnSpellCast(&spell,&player,&spell.info,false);
    assert(summons.size()==10 && player.casts.size()==10);
    for (auto& summon : summons)
    {
        assert(summon->owner==1 && summon->level==60 && summon->lifetime==5000);
        assert(summon->HasAura(707465,1));
        assert(std::abs(summon->motion.destination.x-29.5f)<.0001f);
    }
    spell.triggered=true; cast.OnSpellCast(&spell,&player,&spell.info,false); assert(summons.size()==10);
    runemaster_rift_clone_scaling scaling; SpellInfo info; info.Id=707466; info.SpellFamilyName=38;
    for (float ap : {0.0f,1000.0f,2500.0f})
    {
        player.attackPower=ap; float value=60;
        scaling.ModifySpellEffectBaseValue(summons[0].get(),&info,0,value);
        assert(std::abs(value-(60+ap*.195f))<.001f);
    }
    for (uint32 failure=0;failure<5;++failure)
    {
        auto* summon=summons[failure].get(); auto* brain=brains[failure].get();
        player.alive=failure!=0; player.inWorld=failure!=1; player.phase=failure!=2;
        player.map=failure==3?2:1;
        if (failure==4) player.RemoveAurasDueToSpell(707463,1);
        brain->UpdateAI(249); assert(summon->inWorld);
        brain->UpdateAI(1); assert(!summon->inWorld);
    }
    player.alive=player.inWorld=player.phase=true; player.map=1;
    runemaster_rift_clone_metadata metadata; metadata.OnLoadSpellCustomAttr(&info);
    assert(info.Effects[0].BonusMultiplier==0);
    assert(info.Effects[0].RadiusEntry->RadiusMin==5.0f);
}
''')
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    ids = {707464, 707465, 707466}
    rows = {r[0]: r for r in struct.iter_unpack('<234I', raw[20:20+count*936]) if r[0] in ids}
    assert rows[707464][80] + rows[707464][74] == 10 and rows[707464][40] == 28
    assert rows[707465][95] == 23 and rows[707465][116] == 707466 and rows[707465][98] == 999
    assert rows[707466][86] == 22 and rows[707466][89] == 15
    assert rows[707466][92] == 14
    raw = (dbc_dir() / 'SpellRadius.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    radius = {r[0]: r[1:] for r in struct.iter_unpack('<I3f', raw[20:20+count*16])}
    assert radius[8] == (5.0, 0.0, 5.0)
    print('PASS: ten finite clones, owned appearance/aura, random movement, owner/phase/death cleanup and owner AP')


if __name__ == '__main__':
    main()
