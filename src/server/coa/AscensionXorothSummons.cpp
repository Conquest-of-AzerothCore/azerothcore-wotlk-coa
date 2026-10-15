/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionXoroth.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include "WorldPacket.h"
#include "ThreatManager.h"
#include <algorithm>
#include <cstdlib>
namespace AscensionXoroth
{
void Summon(Player* player, uint32 entry, Position const& position, uint32 duration)
{
    if (!player || !player->IsAlive() || !player->IsInWorld())
        return;
    TempSummon* unit =
        player->GetMap()->SummonCreature(entry, position, nullptr, duration + (entry == 51323 ? 500 : 0), player);
    if (!unit)
        return;
    unit->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
    if (uint32 spell = entry == 50301 ? 807699 : entry == 50375 ? 704247 : 0)
    {
        WorldPacket log(SMSG_SPELLLOGEXECUTE, 8 + 4 + 4 + 4 + 4 + 8);
        log << player->GetPackGUID() << uint32(spell) << uint32(1) << uint32(SPELL_EFFECT_SUMMON) << uint32(1)
            << unit->GetPackGUID();
        player->SendMessageToSet(&log, true);
    }
}
void ImpFormation(uint32 slot, float& distance, float& angle)
{
    static constexpr float spread[] = {0.0f, 0.45f, -0.45f, 0.9f, -0.9f};
    distance = 2.0f + float(slot / 5) * 1.2f;
    angle = float(M_PI) + spread[slot % 5];
}
Position ImpPosition(Player* player)
{
    float distance, angle;
    ImpFormation(uint32(State(player).imps.size()), distance, angle);
    return player->GetNearPosition(distance, angle);
}
}
namespace
{
using namespace AscensionXoroth;
void Scale(Creature* unit, Player* player)
{
    bool imp = unit->GetEntry() == 50301;
    float health = player->GetMaxHealth() * (imp ? .25f : .6f);
    if (imp && player->HasAura(706755))
        health *= 1.3f;
    if (imp && player->HasAura(804879))
        health *= 1.5f;
    if (Aura* grit = player->GetAuraOfRankedSpell(805678))
        health *= 1 + Amount(grit->GetId()) / 100.0f;
    uint32 maximum = std::max(1u, uint32(health));
    float percent = unit->GetHealthPct() / 100.0f;
    unit->SetLevel(player->GetLevel());
    unit->SetMaxHealth(maximum);
    unit->SetHealth(std::max(1u, uint32(maximum * percent)));
    unit->SetArmor(player->GetArmor());
    float damage = player->GetLevel() * 1.5f + player->GetTotalAttackPowerValue(BASE_ATTACK) * .10f;
    unit->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage * .8f);
    unit->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.2f);
    unit->UpdateDamagePhysical(BASE_ATTACK);
}
struct npc_ascension_xoroth_summon : public ScriptedAI
{
    explicit npc_ascension_xoroth_summon(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid owner;
    EventMap events;
    uint32 remaining = 0;
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
        if (me->GetEntry() == 51323 || me->GetEntry() == 50268)
        {
            me->SetReactState(REACT_PASSIVE);
            me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            me->GetMotionMaster()->MoveIdle();
            if (me->GetEntry() == 50268)
                me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            else
                remaining = uint32(sSpellMgr->GetSpellInfo(706756)->GetDuration());
        }
        else
        {
            Scale(me, player);
            me->SetFullHealth();
            me->SetReactState(REACT_DEFENSIVE);
            if (me->GetEntry() == 50301)
            {
                me->SetCreatorGUID(owner);
                me->m_ControlledByPlayer = true;
                me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
                me->SetByteValue(UNIT_FIELD_BYTES_2, 1, player->GetByteValue(UNIT_FIELD_BYTES_2, 1));
                State(player).imps.push_back(me->GetGUID());
                me->GetThreatMgr().RegisterRedirectThreat(706571, owner, 100);
                Cast(player, me, 800443);
            }
            else
                Cast(me, me, 302580);
        }
        events.ScheduleEvent(1, 1s);
        Refresh(player);
    }
    void AttackStart(Unit* target) override
    {
        if (target && target != me->GetVictim())
            me->StopMoving();
        ScriptedAI::AttackStart(target);
    }
    void sGossipHello(Player* player) override
    {
        Player* summoner = ObjectAccessor::GetPlayer(*me, owner);
        if (me->GetEntry() == 50268 && summoner && player->IsAlive() && !player->IsInCombat() &&
            player->IsWithinDistInMap(me, 5) && (player == summoner || summoner->IsInRaidWith(player)))
            Cast(player, player, 804775);
    }
    void JustDied(Unit*) override
    {
        if (me->GetEntry() != 50301)
            return;
        if (Player* player = Owner(ObjectAccessor::GetPlayer(*me, owner)); player && player->HasAura(804013))
        {
            Reduce(player, 805677, std::abs(Amount(804012, 0, player)));
            Reduce(player, 524897, std::abs(Amount(804012, 1, player)));
        }
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, owner);
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 100))
        {
            me->DespawnOrUnsummon();
            return;
        }
        if (me->GetEntry() == 51323 && remaining)
        {
            if (diff >= remaining)
            {
                remaining = 0;
                for (Unit* target : Nearby(me, 10))
                    if (player->IsValidAttackTarget(target) &&
                        !target->IsImmunedToSpell(sSpellMgr->GetSpellInfo(803185)) &&
                        !target->IsImmuneToForcedMovement())
                        target->GetMotionMaster()->MoveJump(me->GetPositionX(), me->GetPositionY(), me->GetPositionZ(),
                                                            20, 10);
            }
            else
                remaining -= diff;
        }
        events.Update(diff);
        if (events.ExecuteEvent())
        {
            if (me->GetEntry() == 50301 || me->GetEntry() == 50375)
                Scale(me, player);
            events.ScheduleEvent(1, 2s);
        }
        if (me->GetEntry() == 51323 || me->GetEntry() == 50268)
            return;
        if (me->GetEntry() == 50301)
            for (UnitMoveType type : {MOVE_WALK, MOVE_RUN})
                if (float rate = player->GetSpeedRate(type) * 1.15f; me->GetSpeedRate(type) != rate)
                    me->SetSpeedRate(type, rate);
        if (Unit* target = me->GetVictim(); target && !player->IsValidAttackTarget(target))
            me->AttackStop();
        if (!me->GetVictim())
        {
            Unit* target = player->GetVictim();
            if (target && player->IsValidAttackTarget(target))
                AttackStart(target);
            else if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
            {
                auto const& imps = State(player).imps;
                auto slot = std::find(imps.begin(), imps.end(), me->GetGUID());
                float distance = 2, angle = 0;
                if (me->GetEntry() == 50301 && slot != imps.end())
                    ImpFormation(uint32(slot - imps.begin()), distance, angle);
                me->GetMotionMaster()->MoveFollow(player, distance, angle, MOTION_SLOT_ACTIVE, true,
                                                  me->GetEntry() != 50301);
            }
        }
        bool engaged = UpdateVictim();
        if ((engaged && me->GetEntry() == 50375) || (me->GetEntry() == 50301 && me->GetVictim()))
            DoMeleeAttackIfReady();
    }
};
class spell_ascension_xoroth_sacrificial_circle : public SpellScript
{
    PrepareSpellScript(spell_ascension_xoroth_sacrificial_circle);
    static bool OwnImp(Player const* player, WorldObject const* object)
    {
        Creature const* imp = object ? object->ToCreature() : nullptr;
        return imp && imp->GetEntry() == 50301 && imp->IsAlive() && imp->GetOwnerGUID() == player->GetGUID();
    }
    SpellCastResult CheckImps()
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return SPELL_CAST_OK;
        float radius = GetSpellInfo()->Effects[EFFECT_0].CalcRadius(player);
        for (ObjectGuid guid : State(player).imps)
            if (Creature* imp = ObjectAccessor::GetCreature(*player, guid))
                if (OwnImp(player, imp) && imp->IsWithinDistInMap(player, radius))
                    return SPELL_CAST_OK;
        return SPELL_FAILED_CASTER_AURASTATE;
    }
    void SelectImps(std::list<WorldObject*>& targets)
    {
        Player* player = Owner(GetCaster());
        targets.remove_if([player](WorldObject* target) { return !player || !OwnImp(player, target); });
    }
    void PreventLaunchDefault(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }
    void Sacrifice(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = Owner(GetCaster());
        Creature* imp = GetHitCreature();
        if (!player || !OwnImp(player, imp))
            return;
        int32 const healAmount = int32(imp->CountPctFromMaxHealth(25));
        int32 const shieldAmount = int32(imp->CountPctFromMaxHealth(15));
        imp->CastCustomSpell(706753, SPELLVALUE_BASE_POINT0, healAmount, player, TRIGGERED_FULL_MASK);
        if (player->HasAura(706758))
            player->CastCustomSpell(706759, SPELLVALUE_BASE_POINT2, shieldAmount, player, TRIGGERED_FULL_MASK);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_xoroth_sacrificial_circle::CheckImps);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_xoroth_sacrificial_circle::SelectImps,
                                                                  EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_xoroth_sacrificial_circle::PreventLaunchDefault, EFFECT_0,
                                              SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_xoroth_sacrificial_circle::Sacrifice, EFFECT_0,
                                           SPELL_EFFECT_TRIGGER_SPELL);
    }
};
}
void AddSC_AscensionXorothSummons()
{
    RegisterCreatureAI(npc_ascension_xoroth_summon);
    RegisterSpellScript(spell_ascension_xoroth_sacrificial_circle);
}
