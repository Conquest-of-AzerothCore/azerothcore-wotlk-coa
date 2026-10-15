/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionSunCleric.h"
#include "DBCStores.h"
#include "Map.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
namespace AscensionSunCleric
{
namespace
{
constexpr uint32 SunGateEntry = 50331;
enum MovementEvent : uint32 { ValkyrLanding = 1 };
}
void SunGate(Player* player)
{
    if (!player || !player->IsAlive())
        return;
    Position origin = player->GetPosition();
    TempSummon* gate = player->GetMap()->SummonCreature(SunGateEntry,origin,
        sSummonPropertiesStore.LookupEntry(61),sSpellMgr->GetSpellInfo(802161)->GetDuration(),player);
    if (!gate)
        return;
    gate->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
    gate->SetOwnerGUID(player->GetGUID());
    gate->SetReactState(REACT_PASSIVE);
    gate->GetMotionMaster()->Clear();
    gate->GetMotionMaster()->MoveIdle();
    ObjectGuid previous = State(player).gate;
    State(player).gate = gate->GetGUID();
    if (Creature* old = ObjectAccessor::GetCreature(*player,previous);
        old && old->GetEntry() == SunGateEntry && old->GetOwnerGUID() == player->GetGUID())
        old->DespawnOrUnsummon();
    player->RemoveMovementImpairingAuras(true);
    Cast(player,player,802145);
}
void Valkyr(Player* player, Unit* target, bool dawn, bool fulfillment)
{
    if (!player || !target || !player->IsValidAttackTarget(target))
        return;
    ObjectGuid owner = player->GetGUID(), victim = target->GetGUID();
    uint32 map = player->GetMapId();
    Cast(player,player,520025);
    State(player).scheduler.Schedule(Milliseconds(sSpellMgr->GetSpellInfo(520024)->GetDuration()),
        [owner,victim,map,dawn,fulfillment](TaskContext)
        {
            Player* caster = ObjectAccessor::FindPlayer(owner);
            if (!caster || !caster->IsInWorld() || !caster->IsAlive() || caster->GetMapId() != map)
                return;
            Unit* enemy = ObjectAccessor::GetUnit(*caster,victim);
            caster->RemoveAurasDueToSpell(520025);
            if (!enemy || !caster->IsValidAttackTarget(enemy) || !caster->IsWithinDistInMap(enemy,50))
            {
                caster->GetMotionMaster()->MoveFall();
                return;
            }
            Position destination = enemy->GetPosition();
            caster->GetMotionMaster()->MoveCharge(destination.GetPositionX(),destination.GetPositionY(),
                destination.GetPositionZ(),50,ValkyrLanding);
            State(caster).scheduler.Schedule(50ms,[owner,map,destination,dawn,fulfillment](TaskContext context)
            {
                Player* landed = ObjectAccessor::FindPlayer(owner);
                if (!landed || !landed->IsAlive() || !landed->IsInWorld() || landed->GetMapId() != map)
                    return;
                if (!landed->movespline->Finalized())
                {
                    if (context.GetRepeatCounter() < 100)
                        context.Repeat(50ms);
                    return;
                }
                if (landed->GetExactDist(&destination) <= 3)
                {
                    bool oldDawn = State(landed).landingDawn, oldFulfillment = State(landed).landingFulfillment;
                    State(landed).landingDawn = dawn;
                    State(landed).landingFulfillment = fulfillment;
                    landed->CastSpell(destination.GetPositionX(),destination.GetPositionY(),
                        destination.GetPositionZ(),570034,true);
                    State(landed).landingDawn = oldDawn;
                    State(landed).landingFulfillment = oldFulfillment;
                }
            });
        });
}
}
namespace
{
using namespace AscensionSunCleric;
struct npc_ascension_sun_gate : public ScriptedAI
{
    explicit npc_ascension_sun_gate(Creature* creature) : ScriptedAI(creature) { }
    void IsSummonedBy(WorldObject* summoner) override
    {
        if (Player* player = summoner ? summoner->ToPlayer() : nullptr)
            me->SetOwnerGUID(player->GetGUID());
        me->SetReactState(REACT_PASSIVE);
        me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
    }
    void sGossipHello(Player* player) override
    {
        CloseGossipMenuFor(player);
        Player* owner = ObjectAccessor::FindPlayer(me->GetOwnerGUID());
        if (!owner || !player->IsAlive() || !owner->IsAlive() || !player->IsWithinDistInMap(me,INTERACTION_DISTANCE) ||
            !player->IsFriendlyTo(owner) || (player != owner && !player->IsInRaidWith(owner)) || player->HasAura(802148))
            return;
        player->RemoveMovementImpairingAuras(true);
        player->CastSpell(player,802145,true);
        player->CastSpell(player,802148,true);
    }
    void UpdateAI(uint32) override
    {
        Player* owner = ObjectAccessor::FindPlayer(me->GetOwnerGUID());
        if (!owner || !owner->IsAlive() || !owner->IsInWorld() || owner->GetMap() != me->GetMap())
            me->DespawnOrUnsummon();
    }
};
}
void AddSC_AscensionSunClericSummons()
{
    RegisterCreatureAI(npc_ascension_sun_gate);
}
