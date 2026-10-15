import os
from pathlib import Path
import re
import runpy
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def main():
    source = (ROOT / 'src/server/coa/AscensionChronomancerMovement.cpp').read_text()
    source = re.sub(r'^#include.*\n', '', source, flags=re.M)
    method = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    follow = method((ROOT / 'src/server/game/Movement/MotionMaster.cpp').read_text(),
                    'void MotionMaster::MoveFollow(')
    code = r'''
#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <initializer_list>
#include <list>
#include <vector>
using uint32=std::uint32_t;using ObjectGuid=uint32;
using SpellEffIndex=int;using AuraEffectHandleModes=int;
enum SpellCastResult {SPELL_CAST_OK,SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW};
enum {CLASS_CHRONOMANCER=22,POWER_MANA=0,REACT_PASSIVE=0,EFFECT_0=0,EFFECT_1=1,
    SPELL_EFFECT_DUMMY=3,SPELL_AURA_DUMMY=4,AURA_REMOVE_BY_EXPIRE=1,AURA_REMOVE_BY_ENEMY_SPELL=2,
    AURA_EFFECT_HANDLE_REAL=1,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK=3,GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR=1,
    UNIT_FLAG_DISABLE_MOVE=4};
struct Position {float x=0;};
struct SpellInfo
{
    uint32 Id=0,SpellFamilyName=28;struct Slot {int Effect=0;};std::array<Slot,3> Effects;
    bool maskRefreshed=false;void _InitializeExplicitTargetMask(){maskRefreshed=true;}
};
struct Player;struct Creature;
struct Unit
{
    virtual ~Unit()=default;virtual Player* ToPlayer(){return nullptr;}
    uint32 guid=1,hp=900,maxHP=1000,mp=400,maxMP=500,mapId=1,instanceId=1;
    bool alive=true,world=true,transport=false,vehicle=false,flight=false,phase=true;
    Position pos;std::vector<uint32> casts;std::vector<float> castPositions;
    uint32 unitFlags=0;
    void SetUnitFlag(uint32 flag){unitFlags|=flag;}bool HasUnitFlag(uint32 flag)const{return (unitFlags&flag)!=0;}
    bool IsPlayer(){return ToPlayer()!=nullptr;}bool IsAlive()const{return alive;}bool IsInWorld()const{return world;}
    bool GetTransport()const{return transport;}bool GetVehicle()const{return vehicle;}
    bool IsInFlight()const{return flight;}
    uint32 GetGUID()const{return guid;}Position GetPosition()const{return pos;}
    uint32 GetHealth()const{return hp;}uint32 GetPower(int)const{return mp;}
    uint32 GetMaxHealth()const{return maxHP;}uint32 GetMaxPower(int)const{return maxMP;}
    uint32 GetMapId()const{return mapId;}uint32 GetInstanceId()const{return instanceId;}
    uint32 GetMap()const{return mapId*100+instanceId;}
    bool InSamePhase(Unit* unit)const{return phase && unit->phase;}
    void NearTeleportTo(Position const& target,bool=false){pos=target;}
    void SetHealth(uint32 value){hp=value;}void SetPower(int,uint32 value){mp=value;}
    SpellCastResult CastSpell(Unit*,uint32 id,bool)
    {casts.push_back(id);castPositions.push_back(pos.x);return SPELL_CAST_OK;}
};
using WorldObject=Unit;
struct Player:Unit
{
    uint32 cls=22;bool teleporting=false;std::list<Creature*> minions;
    Player* ToPlayer()override{return this;}uint32 getClass()const{return cls;}
    bool IsBeingTeleported()const{return teleporting;}
    void GetAllMinionsByEntry(std::list<Creature*>&,uint32);
};
struct ScriptedAI
{
    Creature* me;explicit ScriptedAI(Creature* unit):me(unit){}virtual ~ScriptedAI()=default;
    virtual void IsSummonedBy(WorldObject*){}virtual void UpdateAI(uint32){}
};
struct Creature:Unit
{
    uint32 entry=50071;ScriptedAI* ai=nullptr;int reaction=1;
    ScriptedAI* AI(){return ai;}Creature* ToTempSummon(){return this;}
    void UnSummon(){world=false;}void SetReactState(int state){reaction=state;}
};
void Player::GetAllMinionsByEntry(std::list<Creature*>& result,uint32 entry)
{for(Creature* pet:minions)if(pet->entry==entry && pet->world)result.push_back(pet);}
struct Hook {void operator+=(int){}};
struct SpellScript
{
    Unit* caster=nullptr;bool prevented=false;Hook OnCheckCast,OnEffectHitTarget;
    virtual ~SpellScript()=default;virtual bool Validate(SpellInfo const*){return true;}virtual void Register(){}
    Unit* GetCaster(){return caster;}bool ValidateSpellInfo(std::initializer_list<uint32>){return true;}
    void PreventHitDefaultEffect(int){prevented=true;}
};
struct AuraEffect{};
struct AuraApplication {int mode=1;int GetRemoveMode()const{return mode;}};
struct AuraScript
{
    Unit* fixtureTarget=nullptr;AuraApplication application;Hook AfterEffectApply,AfterEffectRemove;
    virtual ~AuraScript()=default;virtual void Register(){}
    Unit* GetTarget(){return fixtureTarget;}AuraApplication* GetTargetApplication(){return &application;}
};
struct GlobalScript
{GlobalScript(char const*,std::initializer_list<int>){}virtual void OnLoadSpellCustomAttr(SpellInfo*){}};
#define PrepareSpellScript(name) public:
#define PrepareAuraScript(name) public:
#define SpellCheckCastFn(...) 0
#define SpellEffectFn(...) 0
#define AuraEffectApplyFn(...) 0
#define AuraEffectRemoveFn(...) 0
#define RegisterCreatureAI(...)
#define RegisterSpellScript(...)
using MovementSlot=int;
template<class T> struct FollowMovementGenerator
{FollowMovementGenerator(Unit*,float,float,bool,bool){}};
struct MotionMaster
{
    Unit* _owner;bool following=false;
    template<class T> void Mutate(T* generator,int){following=true;delete generator;}
    void MoveFollow(Unit*,float,float,MovementSlot,bool,bool);
};
#define LOG_DEBUG(...)
''' + follow + source + r'''
int main()
{
    Player player;player.pos.x=10;Creature clone,old;
    npc_ascension_infinite_clone ai(&clone),oldAI(&old);clone.ai=&ai;old.ai=&oldAI;
    player.minions={&old,&clone};ai.IsSummonedBy(&player);
    assert(ai.recorded && !old.world && clone.reaction==REACT_PASSIVE && player.casts.back()==45204);
    // This native call happens after IsSummonedBy in Spell::SummonGuardian.
    MotionMaster cloneMotion{&clone};cloneMotion.MoveFollow(&player,1,0,0,false,false);
    assert(!cloneMotion.following);
    Creature ordinary;MotionMaster ordinaryMotion{&ordinary};
    ordinaryMotion.MoveFollow(&player,1,0,0,false,false);assert(ordinaryMotion.following);
    spell_ascension_rewind rewind;rewind.caster=&player;
    assert(rewind.CheckClone()==SPELL_CAST_OK);
    player.transport=true;assert(rewind.CheckClone()!=SPELL_CAST_OK);player.transport=false;
    player.instanceId=2;assert(rewind.CheckClone()!=SPELL_CAST_OK);player.instanceId=1;
    clone.alive=false;assert(rewind.CheckClone()!=SPELL_CAST_OK);clone.alive=true;
    ai.owner=99;assert(rewind.CheckClone()!=SPELL_CAST_OK);ai.owner=player.guid;
    player.pos.x=99;player.hp=100;player.mp=0;player.maxHP=700;player.maxMP=300;
    rewind.Restore(0);
    assert(rewind.prevented && player.pos.x==10 && player.hp==700 && player.mp==300 && !clone.world);
    assert(player.casts.back()==572883 && player.castPositions.back()==99);
    assert(rewind.CheckClone()!=SPELL_CAST_OK);
    clone.world=true;player.teleporting=true;ai.recorded=false;ai.IsSummonedBy(&player);
    assert(!ai.recorded);player.teleporting=false;

    Unit victim;victim.pos.x=12;aura_ascension_backtrack backtrack;backtrack.fixtureTarget=&victim;
    backtrack.Record(nullptr,1);victim.pos.x=50;backtrack.Return(nullptr,1);assert(victim.pos.x==12);
    victim.pos.x=20;backtrack.Record(nullptr,3);victim.pos.x=60;
    backtrack.application.mode=AURA_REMOVE_BY_ENEMY_SPELL;backtrack.Return(nullptr,1);assert(victim.pos.x==60);
    backtrack.application.mode=AURA_REMOVE_BY_EXPIRE;victim.mapId=2;
    backtrack.Return(nullptr,1);assert(victim.pos.x==60);victim.mapId=1;victim.instanceId=2;
    backtrack.Return(nullptr,1);assert(victim.pos.x==60);victim.instanceId=1;victim.vehicle=true;
    backtrack.Return(nullptr,1);assert(victim.pos.x==60);victim.vehicle=false;victim.alive=false;
    backtrack.Return(nullptr,1);assert(victim.pos.x==60);victim.alive=true;
    backtrack.Return(nullptr,1);assert(victim.pos.x==20);
    SpellInfo info;info.Id=706973;info.Effects[0].Effect=140;info.Effects[1].Effect=6;
    chronomancer_movement_contracts contracts;contracts.OnLoadSpellCustomAttr(&info);
    assert(!info.Effects[0].Effect && info.Effects[1].Effect==6 && info.maskRefreshed);
}
'''
    compiler = str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe')
    with tempfile.TemporaryDirectory(prefix='coa-chrono-movement-') as directory:
        out = Path(directory)
        cpp, exe = out / 'movement.cpp', out / 'movement.exe'
        cpp.write_text(code, encoding='utf-8')
        subprocess.run([compiler, '/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8',
                        str(cpp), '/Fe' + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: owned live clone, bounded restoration, departure slow, Backtrack expiry/dispel/map/instance gates')


if __name__ == '__main__':
    main()
