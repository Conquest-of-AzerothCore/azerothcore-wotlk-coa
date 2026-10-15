/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPyromancer.h"
#include "CharmInfo.h"
#include "DBCStores.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <set>
namespace AscensionPyromancer
{
void Summon(Player* player, uint32 entry, uint32 propertiesId, Position const& position, uint32 duration)
{
    auto properties = sSummonPropertiesStore.LookupEntry(propertiesId);
    if (!player || !player->IsAlive() || !properties || (entry != 50258 && entry != 50359 && entry != 52258))
        return;
    if (TempSummon* summon = player->GetMap()->SummonCreature(entry, position, properties, duration, player))
        summon->SetTempSummonType(duration ? TEMPSUMMON_TIMED_DESPAWN : TEMPSUMMON_DEAD_DESPAWN);
}
bool CanPhoenixCommand(Player* player, Unit* target, bool dive)
{
    if (!player || !player->IsAlive())
        return false;
    if (Creature* phoenix = ObjectAccessor::GetCreature(*player, State(player).phoenix))
        return phoenix->IsAlive() && phoenix->GetOwnerGUID() == player->GetGUID() &&
               player->IsWithinDistInMap(phoenix, 60) && player->InSamePhase(phoenix) &&
               (!dive || (target && target->IsAlive() && player->IsValidAssistTarget(target) &&
                          phoenix->IsWithinDistInMap(target, 60) && phoenix->IsWithinLOSInMap(target)));
    return false;
}
void PhoenixCommand(Player* player, Unit* target, bool dive)
{
    if (CanPhoenixCommand(player, target, dive))
        if (Creature* phoenix = ObjectAccessor::GetCreature(*player, State(player).phoenix))
        {
            phoenix->AI()->SetGUID(target ? target->GetGUID() : player->GetGUID());
            phoenix->AI()->DoAction(dive ? 1 : 2);
        }
}
}
namespace
{
using namespace AscensionPyromancer;
Milliseconds PhoenixPeriod(Player* player)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(712290);
    int32 period = info ? info->Effects[EFFECT_0].Amplitude : 5000;
    player->ApplySpellMod(712290, SPELLMOD_ACTIVATION_TIME, period);
    return Milliseconds(std::max(period, 1));
}
struct npc_ascension_pyromancer_summon : public ScriptedAI
{
    explicit npc_ascension_pyromancer_summon(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid owner, command;
    EventMap timers;
    uint32 dormant = 0, diveTime = 0;
    Position previous;
    std::set<ObjectGuid> shielded, occupants;
    bool firstShield = false;
    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = Owner(summoner ? summoner->ToUnit() : nullptr);
        if (!player)
        {
            me->DespawnOrUnsummon();
            return;
        }
        owner = player->GetGUID();
        me->SetOwnerGUID(owner);
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetMaxHealth(std::max(1u, player->GetMaxHealth() / 2));
        me->SetHealth(me->GetMaxHealth());
        me->SetArmor(player->GetArmor());
        me->SetReactState(REACT_PASSIVE);
        if (me->GetEntry() == 50258 || me->GetEntry() == 50359)
        {
            ObjectGuid& owned = me->GetEntry() == 50258 ? State(player).phoenix : State(player).pyre;
            if (Creature* old = ObjectAccessor::GetCreature(*me, owned); old && old->GetOwnerGUID() == owner)
                old->DespawnOrUnsummon();
            owned = me->GetGUID();
        }
        if (me->GetEntry() == 50359)
            me->CastSpell(me, 704279, true);
        timers.ScheduleEvent(1, me->GetEntry() == 50258 ? PhoenixPeriod(player) : 200ms);
        FollowOwner(player);
    }
    void FollowOwner(Player* player)
    {
        if (me->GetEntry() != 50258 || diveTime || dormant ||
            me->GetMotionMaster()->GetCurrentMovementGeneratorType() != IDLE_MOTION_TYPE)
            return;
        if (CharmInfo* charm = me->GetCharmInfo(); charm && !charm->HasCommandState(COMMAND_FOLLOW))
            return;
        me->GetMotionMaster()->MoveFollow(player, PET_FOLLOW_DIST, me->GetFollowAngle());
    }
    void ShowNativeModel() { me->SetDisplayId(me->GetNativeDisplayId(), me->GetNativeObjectScale()); }
    void SetGUID(ObjectGuid const& guid, int32 = 0) override { command = guid; }
    void DoAction(int32 action) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || me->GetEntry() != 50258)
            return;
        if (action == 1)
        {
            if (Unit* target = ObjectAccessor::GetUnit(*me, command);
                target && player->IsValidAssistTarget(target) && me->IsWithinLOSInMap(target))
            {
                previous = me->GetPosition();
                shielded.clear();
                firstShield = true;
                diveTime = 4000;
                ShowNativeModel();
                me->GetMotionMaster()->Clear(false);
                me->GetMotionMaster()->MoveCharge(target->GetPositionX(), target->GetPositionY(),
                                                  target->GetPositionZ(), 25);
            }
        }
        if (action == 2)
        {
            dormant = std::max(1, sSpellMgr->GetSpellInfo(707060)->GetDuration());
            diveTime = 0;
            me->GetMotionMaster()->Clear(false);
            me->GetMotionMaster()->MoveIdle();
            me->SetDisplayId(20245);
            timers.RescheduleEvent(1, 2s);
        }
    }
    void Shields(Player* player)
    {
        float dx = me->GetPositionX() - previous.GetPositionX(), dy = me->GetPositionY() - previous.GetPositionY();
        float length = dx * dx + dy * dy;
        if (!firstShield && length < .0001f)
            return;
        firstShield = false;
        uint32 maximum = sSpellMgr->GetSpellInfo(706855)->Effects[0].ChainTarget;
        if (!maximum)
            maximum = 5;
        for (Unit* ally : Allies(player, me, std::sqrt(length) + 3, 40))
        {
            if (shielded.size() >= maximum)
                break;
            float t = length ? std::clamp(((ally->GetPositionX() - previous.GetPositionX()) * dx +
                                           (ally->GetPositionY() - previous.GetPositionY()) * dy) /
                                              length,
                                          0.0f, 1.0f)
                             : 0;
            float x = previous.GetPositionX() + t * dx, y = previous.GetPositionY() + t * dy;
            if (ally->GetExactDist2d(x, y) <= 3 && std::abs(ally->GetPositionZ() - me->GetPositionZ()) < 5 &&
                shielded.insert(ally->GetGUID()).second)
                Cast(player, ally, 706855);
        }
        previous = me->GetPosition();
    }
    void JustDied(Unit*) override
    {
        if (me->GetEntry() == 50258)
            if (Player* player = ObjectAccessor::GetPlayer(*me, owner); player && player->HasAura(806779))
                for (Unit* ally : Allies(player, me, 30, 40))
                    Copy(player, ally, 712482, me->GetMaxHealth());
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 100) || !me->InSamePhase(player))
        {
            me->DespawnOrUnsummon();
            return;
        }
        if (diveTime)
        {
            Shields(player);
            diveTime = diveTime > diff ? diveTime - diff : 0;
            if (!diveTime)
                ShowNativeModel();
        }
        if (dormant)
        {
            dormant = dormant > diff ? dormant - diff : 0;
            if (!dormant)
                ShowNativeModel();
        }
        FollowOwner(player);
        timers.Update(diff);
        if (timers.ExecuteEvent() != 1)
            return;
        if (me->GetEntry() == 50258)
        {
            uint32 id = dormant ? 706856 : 707110;
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            float radius = info->Effects[0].CalcRadius(player);
            for (Unit* ally : Allies(player, me, radius > 0 ? radius : 15, info->MaxAffectedTargets))
                Cast(player, ally, id);
        }
        if (me->GetEntry() == 52258)
        {
            std::set<ObjectGuid> current;
            float radius = sSpellMgr->GetSpellInfo(802791)->Effects[0].CalcRadius(player);
            for (Unit* enemy : Nearby(me, radius > 0 ? radius : 6))
                if (player->IsValidAttackTarget(enemy) && me->IsWithinLOSInMap(enemy))
                {
                    current.insert(enemy->GetGUID());
                    if (!occupants.count(enemy->GetGUID()))
                        me->CastSpell(enemy, 803704, true, nullptr, nullptr, owner);
                }
            occupants.swap(current);
        }
        Milliseconds next = 5000ms;
        if (me->GetEntry() == 52258)
            next = 200ms;
        else if (dormant)
            next = 2000ms;
        else if (me->GetEntry() == 50258)
            next = PhoenixPeriod(player);
        timers.ScheduleEvent(1, next);
    }
};
}
void AddSC_AscensionPyromancerSummons()
{
    RegisterCreatureAI(npc_ascension_pyromancer_summon);
}
