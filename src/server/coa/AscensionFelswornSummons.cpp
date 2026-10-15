/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFelsworn.h"
#include "AscensionFelswornData.h"
#include "DBCStores.h"
#include "GameObject.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace AscensionFelsworn
{
void Summon(Player* player, Position const& position, bool extended)
{
    auto properties = sSummonPropertiesStore.LookupEntry(61);
    if (!properties || !player || !player->IsAlive() || !player->IsInWorld())
        return;
    uint32 duration = 15000 + (extended ? 1000 : 0);
    if (TempSummon* unit = player->GetMap()->SummonCreature(51320, position, properties, duration, player, 572163))
        unit->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
}
}
namespace
{
using namespace AscensionFelsworn;
struct npc_ascension_felsworn_infernal : public ScriptedAI
{
    explicit npc_ascension_felsworn_infernal(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid owner;
    EventMap timers;
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
        Scale(player);
        me->SetReactState(REACT_DEFENSIVE);
        State(player).infernals.push_back(me->GetGUID());
        timers.ScheduleEvent(1, 1s);
    }
    void Scale(Player* player)
    {
        float damage = player->GetLevel() * 2.0f + player->GetTotalAttackPowerValue(BASE_ATTACK) * .10f +
                       std::max(player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE),
                                player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)) *
                           .15f;
        me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, std::max(1.0f, damage * .8f));
        me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, std::max(1.0f, damage * 1.2f));
        me->UpdateDamagePhysical(BASE_ATTACK);
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 100.0f))
        {
            me->DespawnOrUnsummon();
            return;
        }
        timers.Update(diff);
        if (timers.ExecuteEvent())
        {
            Scale(player);
            timers.ScheduleEvent(1, 1s);
        }
        if (Unit* target = me->GetVictim(); target && !player->IsValidAttackTarget(target))
            me->AttackStop();
        if (!me->GetVictim())
        {
            Unit* target = player->GetVictim();
            if (!target)
                target = player->GetSelectedUnit();
            if (target && player->IsValidAttackTarget(target))
                AttackStart(target);
            else if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
                me->GetMotionMaster()->MoveFollow(player, 2.0f, 0);
        }
        if (UpdateVictim())
            DoMeleeAttackIfReady();
    }
};
class go_ascension_felsworn_rift : public GameObjectScript
{
  public:
    go_ascension_felsworn_rift() : GameObjectScript("go_ascension_felsworn_rift") {}
    bool OnGossipHello(Player* player, GameObject* object) override
    {
        Player* owner = Owner(object->GetOwner());
        if (!owner || !player->IsAlive() || player->IsInCombat() || (player != owner && !owner->IsInRaidWith(player)) ||
            !player->InSamePhase(object) || !player->IsWithinDistInMap(object, 5.0f))
            return true;
        for (auto const& rift : FelswornRifts)
            if (rift.entry == object->GetEntry())
            {
                player->TeleportTo(rift.map, rift.x, rift.y, rift.z, rift.orientation);
                return true;
            }
        return true;
    }
};
}
void AddSC_AscensionFelswornSummons()
{
    RegisterCreatureAI(npc_ascension_felsworn_infernal);
    new go_ascension_felsworn_rift();
}
