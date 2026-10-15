/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCultist.h"
#include "DBCStores.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
#include <algorithm>
namespace AscensionCultist
{
namespace
{
constexpr uint32 HallucinationEntry = 840025;
enum SummonEvent : uint32 { Pulse = 1 };
bool Tentacle(uint32 entry)
{
    return entry == CthunTentacle || entry == 501464 || entry == 500465 || entry == 50096 || entry == 500464;
}
void Wander(Creature* creature)
{
    creature->SetWalk(false);
    creature->GetMotionMaster()->MovePoint(1, creature->GetNearPosition(20, frand(0, 6.2831853f)), FORCED_MOVEMENT_RUN);
}
}
void Summon(Player* player, uint32 entry, Position const& position, uint32 duration, Unit* target)
{
    if (!player || !player->IsAlive())
        return;
    if (entry == 840000)
        entry = HallucinationEntry;
    bool oldGod = Tentacle(entry) && entry != 500464;
    if (!Tentacle(entry) && entry != 533030 && entry != 397771 && entry != HallucinationEntry &&
        entry != 50298 && entry != 50263)
        return;
    TempSummon* summon = player->GetMap()->SummonCreature(entry, position,
        entry == 50263 ? nullptr : sSummonPropertiesStore.LookupEntry(oldGod ? 63 : 61), duration,
        entry == 50263 ? nullptr : player);
    if (!summon)
        return;
    summon->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
    summon->GetMotionMaster()->Clear();
    summon->GetMotionMaster()->MoveIdle();
    if (entry == HallucinationEntry)
        Wander(summon);
    if (entry == 50263)
    {
        summon->SetLevel(player->GetLevel());
        summon->SetMaxHealth(std::min<uint64>(UINT32_MAX, uint64(player->GetMaxHealth()) * 10));
        summon->SetHealth(summon->GetMaxHealth());
        summon->SetArmor(player->GetArmor());
        summon->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, player->GetFloatValue(UNIT_FIELD_MINDAMAGE));
        summon->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, player->GetFloatValue(UNIT_FIELD_MAXDAMAGE));
        summon->UpdateDamagePhysical(BASE_ATTACK);
        summon->AI()->AttackStart(player);
    }
    else if (target)
        summon->AI()->SetGUID(target->GetGUID());
}
void Command(Player* player, Unit* target, bool blast)
{
    for (ObjectGuid guid : State(player).summons)
        if (Creature* creature = ObjectAccessor::GetCreature(*player, guid);
            creature && Tentacle(creature->GetEntry()) && creature->GetOwnerGUID() == player->GetGUID() &&
            creature->IsAlive() && player->IsWithinDistInMap(creature, 100))
        {
            if (target)
                creature->AI()->SetGUID(target->GetGUID());
            creature->AI()->DoAction(blast ? 2 : 1);
        }
}
void StartDash(Player* player)
{
    auto& state = State(player);
    state.dashPrevious = player->GetPosition();
    state.dashHits.clear();
    state.dashMs = 2000;
}
void UpdateDash(Player* player, uint32 diff)
{
    auto& state = State(player);
    if (!state.dashMs)
        return;
    float dx = player->GetPositionX() - state.dashPrevious.GetPositionX();
    float dy = player->GetPositionY() - state.dashPrevious.GetPositionY();
    float length = dx * dx + dy * dy;
    if (player->IsAlive() && length > .0001f && length < 2500)
        for (Unit* target : Nearby(player, std::sqrt(length) + 3))
        {
            float t = std::clamp(((target->GetPositionX() - state.dashPrevious.GetPositionX()) * dx +
                (target->GetPositionY() - state.dashPrevious.GetPositionY()) * dy) / length, 0.0f, 1.0f);
            if (target->GetExactDist2d(state.dashPrevious.GetPositionX() + dx * t,
                state.dashPrevious.GetPositionY() + dy * t) <= 2 &&
                std::abs(target->GetPositionZ() - player->GetPositionZ()) < 4 && player->IsValidAttackTarget(target) &&
                player->IsWithinLOSInMap(target) && state.dashHits.insert(target->GetGUID()).second)
                Cast(player, target, 807815);
        }
    state.dashPrevious = player->GetPosition();
    state.dashMs = state.dashMs > diff && player->IsAlive() ? state.dashMs - diff : 0;
}
}
namespace
{
using namespace AscensionCultist;
struct npc_ascension_cultist_summon : public ScriptedAI
{
    explicit npc_ascension_cultist_summon(Creature* creature) : ScriptedAI(creature) { }
    ObjectGuid owner, command;
    std::set<ObjectGuid> participants, afflicted;
    EventMap timers;
    bool portalCast = false;
    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = Owner(summoner ? summoner->ToUnit() : nullptr);
        if (!player)
            return;
        owner = player->GetGUID();
        me->SetOwnerGUID(owner);
        me->SetFaction(player->GetFaction());
        me->SetLevel(player->GetLevel());
        me->SetMaxHealth(std::max(1u, player->GetMaxHealth() / 3));
        me->SetHealth(me->GetMaxHealth());
        me->SetArmor(player->GetArmor());
        me->SetReactState(REACT_PASSIVE);
        me->SetCombatMovement(false);
        State(player).summons.insert(me->GetGUID());
        if (Tentacle(me->GetEntry()) && me->GetEntry() != 500464)
            State(player).tentacle = me->GetGUID();
        if (me->GetEntry() == 500465)
            Cast(me, me, 802045);
        if (me->GetEntry() == HallucinationEntry)
            player->AddAura(49889, me);
        if (me->GetEntry() == 397771)
        {
            me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, player->GetFloatValue(UNIT_FIELD_MINDAMAGE) * .3f);
            me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, player->GetFloatValue(UNIT_FIELD_MAXDAMAGE) * .3f);
            me->UpdateDamagePhysical(BASE_ATTACK);
            me->SetCombatMovement(true);
        }
        if (me->GetEntry() == 50298)
            me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
        timers.ScheduleEvent(Pulse, 100ms);
    }
    void SetGUID(ObjectGuid const& guid, int32 = 0) override { command = guid; }
    void ClearThoughtseize()
    {
        for (ObjectGuid guid : afflicted)
            if (Unit* target = ObjectAccessor::GetUnit(*me, guid))
                target->RemoveAurasDueToSpell(806596, me->GetGUID());
        afflicted.clear();
    }
    void JustDied(Unit*) override
    {
        ClearThoughtseize();
    }
    Unit* Target(Player* player)
    {
        auto valid = [this, player](Unit* unit, bool commanded = false)
        {
            return unit && unit->IsAlive() && player->IsValidAttackTarget(unit) &&
                (commanded || player->IsInCombatWith(unit) || player->IsHostileTo(unit)) &&
                me->IsWithinDistInMap(unit, 40) && me->IsWithinLOSInMap(unit);
        };
        Unit* target = ObjectAccessor::GetUnit(*me, command);
        if (valid(target, true))
            return target;
        if (target = player->GetVictim(); valid(target))
            return target;
        if (target = player->GetSelectedUnit(); valid(target))
            return target;
        for (Unit* enemy : Nearby(me, 30))
            if (valid(enemy))
                return enemy;
        return nullptr;
    }
    void DoAction(int32 action) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || !Tentacle(me->GetEntry()))
            return;
        if (Unit* target = Target(player))
        {
            me->SetFacingToObject(target);
            if (action == 1 && me->GetEntry() == 50096)
                Cast(me, target, 802046);
            if (action == 2)
                Cast(me, target, 573311);
        }
    }
    void sGossipHello(Player* player) override
    {
        Player* summoner = ObjectAccessor::GetPlayer(*me, owner);
        if (me->GetEntry() != 50298 || !summoner || !player->IsAlive() ||
            (player != summoner && !summoner->IsInRaidWith(player)) || !player->IsWithinDistInMap(me, 10))
            return;
        participants.insert(player->GetGUID());
        player->CastSpell(me, 800965, false);
        CloseGossipMenuFor(player);
    }
    void Ritual(Player* player)
    {
        std::vector<Player*> active;
        for (auto it = participants.begin(); it != participants.end();)
        {
            Player* member = ObjectAccessor::GetPlayer(*me, *it);
            Spell* channel = member ? member->GetCurrentSpell(CURRENT_CHANNELED_SPELL) : nullptr;
            if (!member || !member->IsAlive() || !member->IsWithinDistInMap(me, 10) ||
                (member != player && !player->IsInRaidWith(member)) || !channel || !channel->IsChannelActive() ||
                channel->GetSpellInfo()->Id != 800965 || channel->m_targets.GetUnitTargetGUID() != me->GetGUID())
                it = participants.erase(it);
            else
            {
                active.push_back(member);
                ++it;
            }
        }
        if (active.size() >= 10)
        {
            Summon(player, 50263, me->GetPosition(), sSpellMgr->GetSpellInfo(804779)->GetDuration());
            for (Player* member : active)
                member->InterruptSpell(CURRENT_CHANNELED_SPELL);
            me->DespawnOrUnsummon();
            return;
        }
        for (Player* member : active)
            member->ModifyHealth(-int32(std::min(member->GetHealth() - 1, std::max(1u, member->GetMaxHealth() / 100))));
    }
    void UpdateAI(uint32 diff) override
    {
        if (me->GetEntry() == 50263)
        {
            if (UpdateVictim())
                DoMeleeAttackIfReady();
            return;
        }
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 100) || !me->InSamePhase(player))
        {
            me->DespawnOrUnsummon();
            return;
        }
        timers.Update(diff);
        if (!timers.ExecuteEvent())
            return;
        uint32 entry = me->GetEntry();
        timers.ScheduleEvent(Pulse, entry == CthunTentacle ? 1500ms :
            (entry == 501464 || entry == 500464) ? 6000ms : 1000ms);
        if (entry == 50298)
        {
            Ritual(player);
            return;
        }
        if (entry == HallucinationEntry)
        {
            if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != POINT_MOTION_TYPE)
                Wander(me);
            return;
        }
        if (entry == 500464 && me->GetExactDist2d(player) > 2)
            me->NearTeleportTo(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation());
        Unit* target = Target(player);
        if (!target)
            return;
        me->SetFacingToObject(target);
        if (entry == 533030 && !portalCast)
        {
            portalCast = true;
            uint32 roots[] = {500110, 800416, 805572};
            uint32 spell = Highest(player, roots[urand(0, 2)]);
            me->CastSpell(target, spell, false);
            me->DespawnOrUnsummon(sSpellMgr->GetSpellInfo(spell)->IsChanneled() ? 10000ms : 5000ms);
        }
        else if (entry == CthunTentacle && !me->HasUnitState(UNIT_STATE_CASTING))
            me->CastSpell(target, MentalAssault, false);
        else if (entry == 501464 || entry == 500464)
        {
            Cast(me, target, 806596);
            afflicted.insert(target->GetGUID());
        }
        else if (entry == 397771)
        {
            AttackStart(target);
            DoMeleeAttackIfReady();
        }
        else if (entry == 50096 && !portalCast)
        {
            portalCast = true;
            Cast(me, target, 802046);
        }
    }
    ~npc_ascension_cultist_summon() override
    {
        if (Player* player = ObjectAccessor::FindPlayer(owner))
        {
            State(player).summons.erase(me->GetGUID());
            if (State(player).tentacle == me->GetGUID())
                State(player).tentacle.Clear();
        }
    }
};
class cultist_summon_lifecycle : public AllCreatureScript
{
public:
    cultist_summon_lifecycle() : AllCreatureScript("cultist_summon_lifecycle") { }
    void OnCreatureRemoveWorld(Creature* creature) override
    {
        if (creature->GetEntry() == 501464 || creature->GetEntry() == 500464)
            if (auto* ai = dynamic_cast<npc_ascension_cultist_summon*>(creature->AI()))
                ai->ClearThoughtseize();
    }
};
class cultist_summon_damage : public UnitScript
{
public:
    cultist_summon_damage() : UnitScript("cultist_summon_damage", true, {UNITHOOK_ON_DAMAGE}) { }
    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        Player* player = Owner(attacker);
        Creature* creature = attacker ? attacker->ToCreature() : nullptr;
        if (!player || !creature || !damage || State(player).event || !State(player).summons.count(creature->GetGUID()))
            return;
        State(player).event = true;
        if (creature->GetEntry() == 397771)
            Copy(player, player, 680769, player->GetCreateHealth() / 20);
        if (Tentacle(creature->GetEntry()) && player->HasAura(706187))
            for (Unit* ally : Allies(player, creature, 40))
                if (ally->HasAura(BlackBlood, player->GetGUID()))
                    Copy(player, ally, 500773, CalculatePct(std::min(damage, victim->GetHealth()), Amount(706187)));
        State(player).event = false;
    }
};
}
void AddSC_AscensionCultistSummons()
{
    RegisterCreatureAI(npc_ascension_cultist_summon);
    new cultist_summon_lifecycle();
    new cultist_summon_damage();
}
