/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionVenomancer.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
namespace AscensionVenomancer
{
namespace
{
enum SummonEvent : uint32 { Pulse = 1, Detonate = 2 };
enum SummonData : uint32 { MushroomScaling = 1, LargeMushroom = 2, PulseCounter = 3 };
constexpr uint32 FungarianEntry = 45896;
constexpr uint32 MushroomEntry = 506018;
constexpr uint32 BroodTrapEntry = 52121;
constexpr uint32 SpiderlingEntry = 999298;
constexpr uint32 ScarabEntry = 999299;
Unit* OwnerTarget(Player* player)
{
    if (Unit* victim = player->GetVictim(); victim && victim->IsAlive() && player->IsValidAttackTarget(victim))
        return victim;
    Unit* selected = player->GetSelectedUnit();
    return selected && selected->IsAlive() && player->IsValidAttackTarget(selected) &&
        player->IsInCombatWith(selected) ? selected : nullptr;
}
}
void Mushroom(Player* player, Position const& position, float coefficient, bool big)
{
    if (!player || !player->IsAlive())
        return;
    TempSummon* summon = player->GetMap()->SummonCreature(MushroomEntry,position,
        sSummonPropertiesStore.LookupEntry(61),10000,player);
    if (!summon)
        return;
    summon->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
    summon->GetMotionMaster()->Clear();
    summon->GetMotionMaster()->MoveIdle();
    summon->AI()->SetData(MushroomScaling,uint32(coefficient*10000));
    summon->AI()->SetData(LargeMushroom,big);
    if (big)
        summon->SetObjectScale(summon->GetObjectScale()*2);
    if (player->HasAura(706956))
        Reduce(player,800910,std::abs(Amount(707564)));
}
void Summon(Player* player, Unit* target, uint32 spell, Position const* position)
{
    if (!player || !player->IsAlive())
        return;
    Position pos = position ? *position : target ? target->GetPosition() : player->GetNearPosition(2,0);
    if (spell == 680764 || spell == 712357)
    {
        Mushroom(player,pos,spell == 712357 ? .125f : .25f);
        return;
    }
    uint32 entry = spell == 504344 ? FungarianEntry : spell == 560989 ? ScarabEntry :
        spell == 803525 ? BroodTrapEntry : SpiderlingEntry;
    uint32 duration = spell == 807611 ? 15000 : uint32(std::max(1,sSpellMgr->GetSpellInfo(spell)->GetDuration()));
    uint32 count = spell == 807611 ? 2 : spell == 807702 ? uint32(std::max(1,Amount(807702))) : 1;
    if (spell == 504344 && player->HasAura(681054))
        count += uint32(std::max(0,Amount(681054)));
    for (uint32 n = 0; n < count; ++n)
    {
        TempSummon* summon = player->GetMap()->SummonCreature(entry,pos,sSummonPropertiesStore.LookupEntry(61),duration,player);
        if (!summon)
            continue;
        summon->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
        summon->GetMotionMaster()->Clear();
        if (entry == BroodTrapEntry)
        {
            summon->GetMotionMaster()->MoveIdle();
            auto& traps = State(player).traps;
            traps.push_back(summon->GetGUID());
            while (traps.size() > 6)
            {
                ObjectGuid old = traps.front();
                traps.pop_front();
                if (Creature* creature = ObjectAccessor::GetCreature(*player,old))
                    creature->DespawnOrUnsummon();
            }
        }
        else if (target && player->IsValidAttackTarget(target))
            summon->AI()->SetGUID(target->GetGUID());
        else
            summon->GetMotionMaster()->MoveFollow(player,3,0);
    }
}
void ExitParasite(Player* player)
{
    auto& state = State(player);
    if (state.parasiteExit || (state.host.IsEmpty() && !player->HasAura(800921)))
        return;
    state.parasiteExit = true;
    ObjectGuid guid = state.host;
    state.host.Clear();
    Unit* host = ObjectAccessor::GetUnit(*player,guid);
    if (host)
    {
        state.exit.Relocate(*host);
        host->RemoveAurasDueToSpell(804003,player->GetGUID());
    }
    player->RemoveAurasDueToSpell(800921);
    player->SetControlled(false,UNIT_STATE_ROOT);
    if (player->IsAlive() && player->GetMapId() == state.hostMap)
    {
        player->NearTeleportTo(state.exit.GetPositionX(),state.exit.GetPositionY(),state.exit.GetPositionZ(),state.exit.GetOrientation());
        if (host && player->IsValidAttackTarget(host))
            Cast(player,host,807758);
    }
    SpellInfo const* info = sSpellMgr->GetSpellInfo(800921);
    uint32 seconds = std::max(info->RecoveryTime,info->CategoryRecoveryTime) / 1000;
    player->AddSpellCooldown(800921,0,uint32(GameTime::GetGameTime().count())+seconds,true);
    player->removeSpell(803537,SPEC_MASK_ALL,true);
    state.parasiteExit = false;
}
}
namespace
{
using namespace AscensionVenomancer;
struct npc_ascension_venomancer_summon : public ScriptedAI
{
    explicit npc_ascension_venomancer_summon(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid owner, command;
    EventMap timers;
    uint32 coefficient = 2500;
    bool big = false, activated = false, swarm = false;
    float weaponMinimum = 1, weaponMaximum = 2;
    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = Owner(summoner ? summoner->ToUnit() : nullptr);
        if (!player)
            return;
        owner = player->GetGUID();
        me->SetOwnerGUID(owner);
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetMaxHealth(std::max(1u,player->GetMaxHealth()/5));
        me->SetHealth(me->GetMaxHealth());
        me->SetArmor(player->GetArmor()/2);
        me->SetReactState(REACT_PASSIVE);
        bool stationary = me->GetEntry() == MushroomEntry || me->GetEntry() == BroodTrapEntry;
        me->SetCombatMovement(!stationary);
        if (me->GetEntry() == MushroomEntry)
            me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        weaponMinimum = std::max(1.0f,player->GetTotalAttackPowerValue(BASE_ATTACK)*.05f);
        weaponMaximum = std::max(2.0f,player->GetTotalAttackPowerValue(BASE_ATTACK)*.075f);
        me->SetBaseWeaponDamage(BASE_ATTACK,MINDAMAGE,weaponMinimum);
        me->SetBaseWeaponDamage(BASE_ATTACK,MAXDAMAGE,weaponMaximum);
        me->UpdateDamagePhysical(BASE_ATTACK);
        State(player).summons.insert(me->GetGUID());
        timers.ScheduleEvent(me->GetEntry() == MushroomEntry ? Detonate : Pulse,
            me->GetEntry() == MushroomEntry ? 2000ms : 200ms);
    }
    void SetGUID(ObjectGuid const& guid, int32 = 0) override { command = guid; }
    void SetData(uint32 key, uint32 value) override
    {
        if (key == MushroomScaling)
            coefficient = value;
        if (key == LargeMushroom)
            big = value != 0;
    }
    void DamageDealt(Unit* target, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (damage && me->GetEntry() == SpiderlingEntry)
            if (Player* player = ObjectAccessor::FindPlayer(owner); player && player->IsInMap(me))
                ApplyVenoms(player, target, true);
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::FindPlayer(owner);
        if (!player || !player->IsAlive() || !player->IsInMap(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        timers.Update(diff);
        bool enabled = player->HasAura(704264) && player->HasAura(Beetle) && player->HasAura(560247);
        if (swarm != enabled && me->GetEntry() != MushroomEntry && me->GetEntry() != BroodTrapEntry)
        {
            swarm = enabled;
            me->ApplyAttackTimePercentMod(BASE_ATTACK,float(Amount(704264)),swarm);
            float factor = swarm ? 1 + Amount(704264) / 100.0f : 1;
            me->SetBaseWeaponDamage(BASE_ATTACK,MINDAMAGE,weaponMinimum * factor);
            me->SetBaseWeaponDamage(BASE_ATTACK,MAXDAMAGE,weaponMaximum * factor);
            me->UpdateDamagePhysical(BASE_ATTACK);
        }
        if (uint32 event = timers.ExecuteEvent())
        {
            if (event == Detonate)
            {
                float old = State(player).mushroomCoefficient;
                State(player).mushroomCoefficient = coefficient / 10000.0f;
                for (Unit* enemy : Nearby(me,Radius(big ? 503925 : 504543)))
                    if (player->IsValidAttackTarget(enemy))
                        Cast(player,enemy,big ? 503925 : 504543);
                State(player).mushroomCoefficient = old;
                me->DespawnOrUnsummon();
                return;
            }
            Unit* target = ObjectAccessor::GetUnit(*me,command);
            if (me->GetEntry() == FungarianEntry)
                if (Unit* assisted = OwnerTarget(player))
                    target = assisted;
            if (!target || !target->IsAlive() || !player->IsValidAttackTarget(target))
                target = player->GetVictim();
            if (me->GetEntry() == BroodTrapEntry)
            {
                for (Unit* enemy : Nearby(me,3))
                    if (!activated && player->IsValidAttackTarget(enemy))
                    {
                        activated = true;
                        Cast(player,enemy,803724);
                        if (enemy->IsPlayer())
                            if (Aura* root = enemy->GetAura(803724,owner))
                                root->SetDuration(std::min(6000,root->GetDuration()));
                        Cast(player,enemy,807611);
                        Summon(player,enemy,807611);
                        me->DespawnOrUnsummon();
                        return;
                    }
                timers.ScheduleEvent(Pulse,200ms);
                return;
            }
            if (target && target->IsAlive() && player->IsValidAttackTarget(target))
            {
                AttackStart(target);
                if (me->GetEntry() == FungarianEntry && me->IsWithinMeleeRange(target))
                    Cast(me,target,503929);
            }
            else
            {
                me->AttackStop();
                me->GetMotionMaster()->MoveFollow(player,3,0);
            }
            timers.ScheduleEvent(Pulse,Milliseconds(me->GetEntry() == FungarianEntry ? me->GetAttackTime(BASE_ATTACK) : 1000));
        }
        if (me->GetEntry() != MushroomEntry && me->GetEntry() != BroodTrapEntry && me->GetEntry() != FungarianEntry)
            DoMeleeAttackIfReady();
    }
    ~npc_ascension_venomancer_summon() override
    {
        if (Player* player = ObjectAccessor::FindPlayer(owner))
        {
            State(player).summons.erase(me->GetGUID());
            State(player).traps.remove(me->GetGUID());
        }
    }
};
class venomancer_kills : public PlayerScript
{
public:
    venomancer_kills() : PlayerScript("venomancer_kills",{PLAYERHOOK_ON_CREATURE_KILL,PLAYERHOOK_ON_PVP_KILL}) { }
    void OnPlayerCreatureKill(Player* player, Creature* killed) override
    {
        if (Owner(player) == player && killed && player->isHonorOrXPTarget(killed) && Chance(player,504855,1000))
            Mushroom(player,*killed);
    }
    void OnPlayerPVPKill(Player* player, Player* killed) override
    {
        if (Owner(player) == player && killed && player->isHonorOrXPTarget(killed) && Chance(player,504855,1000))
            Mushroom(player,*killed);
    }
};
}
void AddSC_AscensionVenomancerSummons()
{
    RegisterCreatureAI(npc_ascension_venomancer_summon);
    new venomancer_kills();
}
