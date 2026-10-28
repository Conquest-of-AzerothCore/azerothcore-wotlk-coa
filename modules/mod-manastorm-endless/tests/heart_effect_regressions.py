"""Extract production heart/drop and effect-174 implementations into a C++ fixture.
Usage: python heart_effect_regressions.py path/to/output.cpp
"""
from pathlib import Path
import sys
root = Path(__file__).resolve().parents[3]
def function(text, signature):
    start = text.index(signature)
    brace = text.index('{', start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]
mgr = (root / 'modules/mod-manastorm-endless/src/ManastormMgr.cpp').read_text(encoding='utf-8')
effects = (root / 'src/server/game/Spells/SpellEffects.cpp').read_text(encoding='utf-8')
source = r"""
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <limits>
#include <set>
#include <iostream>
using uint8=uint8_t; using uint32=uint32_t; using uint64=uint64_t;
using int32=int32_t; using int64=int64_t;
#define LOG_INFO(...) ((void)0)
#define LOG_DEBUG(...) ((void)0)
constexpr uint32 NPC_MANASTORM_HEART=900025, HEART_TRASH_CHANCE_PCT=75;
struct Map { uint32 GetId(){return 1;} uint32 GetInstanceId(){return 1;} } map;
struct Creature;
struct SpellPeriodicAuraLogInfo {
 template<class... Args> SpellPeriodicAuraLogInfo(Args...) {}
};
struct Threat {void ForwardThreatForAssistingMe(...){}};
using Powers=int; constexpr int POWER_ALL=-2;
struct Unit {
 int power=100, maxPower=100; bool alive=true,immune=false;
 virtual Creature* ToCreature(){return nullptr;}
 int getPowerType(){return 0;} int GetPower(int){return power;}
 uint32 GetMaxPower(int){return maxPower;} bool IsAlive(){return alive;}
 bool IsImmunedToAuraPeriodicTick(...){return immune;}
 int32 ModifyPower(int,int32 delta){int old=power;power=int(std::clamp<int64>(int64(power)+delta,0,maxPower));return power-old;}
 void SendPeriodicAuraLog(SpellPeriodicAuraLogInfo*){}
 Threat& GetThreatMgr(){static Threat threat;return threat;}
};
struct Creature : Unit {
 uint32 hp=1000, max=1000, entry=42; uint64 guid=1;
 Creature* ToCreature() override {return this;}
 uint32 GetEntry(){return entry;} bool IsTrigger(){return false;} bool IsPet(){return false;}
 uint32 GetHealth(){return hp;} uint32 GetMaxHealth(){return max;}
 uint64 GetGUID(){return guid;} Map* GetMap(){return &map;}
};
bool IsPlayerControlledCreature(Creature*){return false;}
enum class ManastormRunState {Active, Preparing};
struct ManastormSegment {uint32 ObjectiveCreatureEntry=99;};
struct ManastormRun {
 ManastormRunState state=ManastormRunState::Active; std::set<uint64> rolls;
 std::set<uint8> bossThresholds; bool member=true; ManastormSegment segment;
 ManastormRunState GetState(){return state;}
 bool IsStageCreature(uint64){return member;}
 bool TryMarkTrashHeartRoll(uint64 guid){return rolls.insert(guid).second;}
 ManastormSegment const& GetSegment(){return segment;}
 uint64 GetObjectiveCreatureGuid(){return 99;} uint64 GetRunId(){return 1;}
 bool HasBossHeartThreshold(uint8 v){return bossThresholds.count(v)!=0;}
 void MarkBossHeartThreshold(uint8 v){bossThresholds.insert(v);}
} run;
int rolls=0, launches=0; bool immediate=false; uint32 dice=1;
uint32 urand(uint32,uint32){++rolls;return dice;}
struct ManastormMgr {
 ManastormRun* GetRunForStage(uint32,uint32){return &run;}
 bool SpawnHeartProjectile(Creature*,ManastormRun&,bool persistentLauncher=false){++launches;immediate=persistentLauncher;return true;}
 bool TrySpawnTrashHeart(Creature*,ManastormRun&);
 void OnDamage(Unit*,Unit*,uint32);
};
struct Target {uint32 hp=1000; bool alive=true; bool IsAlive(){return alive;} uint32 GetMaxHealth(){return hp;}};
struct Effect {int32 MiscValue=0;};
struct Info {uint32 Id=93358; Effect Effects[3];};
constexpr int SPELL_EFFECT_HANDLE_LAUNCH_TARGET=1;
using SpellEffIndex=int;
struct Spell {
 int effectHandleMode=1; Target* unitTarget; Info* m_spellInfo;
 int32 damage=30,m_damage=0;
 void EffectAscensionHealthPctDamage(SpellEffIndex);
};
"""
spawn_impl = function(mgr, 'bool ManastormMgr::SpawnHeartProjectile(')
death_impl = function(mgr, 'void ManastormMgr::OnUnitDeath(')
assert 'SummonTrigger(' in spawn_impl
assert 'SPELL_MANASTORM_HEART_PROJECTILE' in spawn_impl
assert 'lethal ? SPELL_MANASTORM_HEART_SUMMON' not in spawn_impl
assert 'TrySpawnTrashHeart(' in death_impl
source += function(mgr, 'bool ManastormMgr::TrySpawnTrashHeart(')
source += function(mgr, 'void ManastormMgr::OnDamage(')
source += function(effects, 'void Spell::EffectAscensionHealthPctDamage(')
auras = (root / 'src/server/game/Spells/Auras/SpellAuraEffects.cpp').read_text(encoding='utf-8')
source += r"""
struct BaseAura {bool permanent=true; bool IsPermanent() const{return permanent;}};
struct AuraEffect {
 int32 m_amount=-5; uint32 id=93489; BaseAura base;
 int GetMiscValue()const{return 0;} uint32 GetId()const{return id;}
 BaseAura const* GetBase()const{return &base;} void* GetSpellInfo()const{return nullptr;}
 void SendTickImmune(Unit*,Unit*)const{}
 void HandleObsModPowerAuraTick(Unit*,Unit*)const;
};
"""
source += function(auras, 'void AuraEffect::HandleObsModPowerAuraTick(')
source += r"""
int main(){
 Unit powerTarget; AuraEffect aura;
 aura.HandleObsModPowerAuraTick(&powerTarget,nullptr); assert(powerTarget.power==95);
 powerTarget.power=2; aura.HandleObsModPowerAuraTick(&powerTarget,nullptr); assert(powerTarget.power==0);
 powerTarget.power=100; aura.id=42;
 aura.HandleObsModPowerAuraTick(&powerTarget,nullptr); assert(powerTarget.power==100);
 aura.id=93489; powerTarget.immune=true;
 aura.HandleObsModPowerAuraTick(&powerTarget,nullptr); assert(powerTarget.power==100);
 powerTarget.immune=false; aura.m_amount=INT32_MIN;
 aura.HandleObsModPowerAuraTick(&powerTarget,nullptr); assert(powerTarget.power==0);
 aura.id=42; aura.m_amount=5; powerTarget.power=50;
 aura.HandleObsModPowerAuraTick(&powerTarget,nullptr); assert(powerTarget.power==55);
 ManastormMgr mgr; Creature mob;

 // Normal trash is no longer HP-threshold driven.
 mgr.OnDamage(nullptr,&mob,1000);
 assert(rolls==0 && launches==0);
 mob.hp=200;
 mgr.OnDamage(nullptr,&mob,150);
 assert(rolls==0 && launches==0);

 // Death flow owns exactly one 75% trash roll and always requests
 // the persistent 991507 projectile launcher.
 run.rolls.clear(); rolls=launches=0; dice=1;
 mob.hp=0; mob.guid=1; mob.entry=42;
 assert(mgr.TrySpawnTrashHeart(&mob,run));
 assert(rolls==1 && launches==1 && immediate);
 assert(!mgr.TrySpawnTrashHeart(&mob,run));
 assert(rolls==1 && launches==1);

 // A failed 75% roll is consumed too.
 run.rolls.clear(); rolls=launches=0; dice=100;
 assert(!mgr.TrySpawnTrashHeart(&mob,run));
 assert(rolls==1 && launches==0);
 assert(!mgr.TrySpawnTrashHeart(&mob,run));
 assert(rolls==1 && launches==0);

 run.member=false; run.rolls.clear(); dice=1;
 assert(!mgr.TrySpawnTrashHeart(&mob,run));
 run.member=true; run.state=ManastormRunState::Preparing;
 assert(!mgr.TrySpawnTrashHeart(&mob,run));

 // Boss threshold behavior remains unchanged.
 run.state=ManastormRunState::Active; mob.guid=99; mob.entry=99; mob.hp=1000;
 launches=0; mgr.OnDamage(nullptr,&mob,250); assert(launches==2); // Boss 90/80 thresholds preserved.
 Target target; Info info; Spell spell; spell.unitTarget=&target; spell.m_spellInfo=&info;
 spell.EffectAscensionHealthPctDamage(0); assert(spell.m_damage==300);
 spell.m_damage=0; info.Effects[0].MiscValue=1;
 spell.EffectAscensionHealthPctDamage(0); assert(spell.m_damage==300); // Lightning Rod mode 1.
 spell.m_damage=0; info.Id=42;
 spell.EffectAscensionHealthPctDamage(0); assert(spell.m_damage==0); // Unknown mode 1 remains inert.
 info.Id=93008; info.Effects[0].MiscValue=2;
 spell.EffectAscensionHealthPctDamage(0); assert(spell.m_damage==300);
 info.Effects[0].MiscValue=0; target.hp=UINT32_MAX; spell.damage=INT32_MAX;
 spell.EffectAscensionHealthPctDamage(0); assert(spell.m_damage==INT32_MAX);
 spell.m_damage=0; spell.damage=-1;
 spell.EffectAscensionHealthPctDamage(0); assert(spell.m_damage==0);
 std::cout << "Death-driven trash Hearts, persistent projectile launchers, once-only rolls, boss thresholds and effect 174 passed\n";
}
"""
Path(sys.argv[1]).write_text(source, encoding='utf-8', newline='\n')
