/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterCompletion.h"
#include "AscensionSpecialization.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DynamicObject.h"
#include "EventMap.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "PetAI.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace AscensionWitchHunter
{
enum HoundEvents
{
    EVENT_REFRESH_OWNER = 1,
    EVENT_CHECK_LANDING,
    EVENT_AUTO_LEAP,
    EVENT_FIELD_PULSE
};

enum HoundActionsAndPoints
{
    ACTION_CALLED_LEAP = 1,
    GUID_LEAP_TARGET = 1,
    POINT_LEAP_LANDING = 701
};

bool InSmoke(Unit const* attacker, Unit const* target)
{
    if (!attacker || !target || attacker == target || !attacker->IsInWorld() || !target->IsInWorld() ||
        !attacker->IsInMap(target))
        return false;
    for (Unit const* unit : {attacker, target})
        for (auto const& [key, application] : unit->GetAppliedAuras())
        {
            Aura* aura = application->GetBase();
            if (aura->GetId() != 805756 && aura->GetId() != 805757)
                continue;
            if (Unit* caster = aura->GetCaster())
                if (DynamicObject* cloud = caster->GetDynObject(805756))
                    if (cloud->IsWithinDistInMap(attacker, cloud->GetRadius()) !=
                        cloud->IsWithinDistInMap(target, cloud->GetRadius()))
                        return true;
        }
    return false;
}

void SummonHounds(Player* player, uint32 count, uint32 duration, uint32 spellId, Unit* target)
{
    if (!player || !player->IsInWorld() || !player->IsAlive())
        return;
    SummonPropertiesEntry const* properties = sSummonPropertiesStore.LookupEntry(61);
    if (!properties)
        return;
    for (uint32 i = 0; i < std::min(3u, count); ++i)
    {
        Position position = player->GetPosition();
        player->MovePositionToFirstCollision(position, 1.5f, float(i) * 2.1f);
        TempSummon* pet = player->GetMap()->SummonCreature(50224, position, properties, duration, player, spellId);
        if (!pet)
            continue;
        pet->SetTempSummonType(TEMPSUMMON_TIMED_DESPAWN);
        if (target && player->IsValidAttackTarget(target))
            pet->AI()->AttackStart(target);
    }
}

void CallHounds(Player* player, Unit* target)
{
    if (!player || !target || !player->IsValidAttackTarget(target))
        return;
    for (Unit* unit : Nearby(player, 60.0f))
        if (Creature* hound = unit->ToCreature())
            if ((hound->GetEntry() == 50124 || hound->GetEntry() == 50224) &&
                hound->GetOwnerGUID() == player->GetGUID() && hound->IsAIEnabled)
            {
                hound->AI()->SetGUID(target->GetGUID(), GUID_LEAP_TARGET);
                hound->AI()->DoAction(ACTION_CALLED_LEAP);
            }
}
}

namespace
{
using namespace AscensionWitchHunter;

class HoundActions
{
  public:
    explicit HoundActions(Creature* creature) : _me(creature)
    {
        _events.ScheduleEvent(EVENT_REFRESH_OWNER, 1ms);
        _events.ScheduleEvent(EVENT_AUTO_LEAP, 20s);
    }
    ObjectGuid victim;

    void Leap(bool called = false)
    {
        Player* owner = Owner(_me->GetOwner());
        Unit* target = ObjectAccessor::GetUnit(*_me, victim);
        if (!owner || !target || !owner->IsValidAttackTarget(target) || !_me->IsWithinDistInMap(target, 40.0f) ||
            !_me->IsWithinLOSInMap(target) || _me->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED))
        {
            _events.RescheduleEvent(EVENT_AUTO_LEAP, 1s);
            return;
        }
        Position end = target->GetPosition();
        target->MovePositionToFirstCollision(end, target->GetCombatReach(), target->GetRelativeAngle(_me));
        _landingChecks = 0;
        _called = called;
        _me->GetMotionMaster()->MoveJump(end, 24.0f, 8.0f, POINT_LEAP_LANDING);
        _events.RescheduleEvent(EVENT_CHECK_LANDING, 500ms);
        _events.RescheduleEvent(EVENT_AUTO_LEAP, _me->HasAura(800528) ? 10s : 20s);
        _me->RemoveAurasDueToSpell(800528);
    }

    void Update(uint32 diff)
    {
        _events.Update(diff);
        while (uint32 event = _events.ExecuteEvent())
        {
            Player* owner = Owner(_me->GetOwner());
            if (!owner || !owner->IsAlive() || !owner->IsInMap(_me) || !owner->InSamePhase(_me))
            {
                if (_me->GetEntry() == 50224)
                    _me->DespawnOrUnsummon();
                continue;
            }
            if (event == EVENT_REFRESH_OWNER)
            {
                if (!_me->getTransForm())
                {
                    uint32 display = GetShadowhoundDisplay(owner);
                    if (!display)
                        display = _me->GetNativeDisplayId();
                    if (_me->GetDisplayId() != display)
                        _me->SetDisplayId(display, _me->GetObjectScale());
                }
                float healthFraction = _me->GetHealthPct() / 100.0f;
                uint32 maximum = std::max(1u, owner->CountPctFromMaxHealth(_me->GetEntry() == 50124 ? 40 : 20));
                if (maximum != _me->GetMaxHealth())
                {
                    _me->SetMaxHealth(maximum);
                    _me->SetHealth(std::max(1u, uint32(maximum * healthFraction)));
                }
                _me->SetLevel(owner->GetLevel());
                float damage = owner->GetLevel() + owner->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.04f;
                _me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, damage * 0.9f);
                _me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, damage * 1.1f);
                _me->UpdateDamagePhysical(BASE_ATTACK);
                if (owner->HasAura(570726) && !_me->HasAura(562027))
                    owner->AddAura(562027, _me);
                if (!owner->HasAura(570726))
                    _me->RemoveAurasDueToSpell(562027);
                if (_me->GetEntry() == 50224 && !_me->GetVictim())
                {
                    Unit* target = owner->GetVictim();
                    if (!target && !owner->getAttackers().empty())
                        target = *owner->getAttackers().begin();
                    if (!target)
                        if (Unit* selected = owner->GetSelectedUnit())
                            if (selected->IsInCombatWith(owner))
                                target = selected;
                    if (target && owner->IsValidAttackTarget(target))
                        _me->AI()->AttackStart(target);
                    else if (_me->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
                        _me->GetMotionMaster()->MoveFollow(owner, 2.0f, PET_FOLLOW_ANGLE);
                }
                _events.ScheduleEvent(EVENT_REFRESH_OWNER, 1s);
            }
            else if (event == EVENT_CHECK_LANDING)
            {
                Unit* target = ObjectAccessor::GetUnit(*_me, victim);
                if (!target || !owner->IsValidAttackTarget(target))
                    continue;
                if (!_me->IsWithinMeleeRange(target))
                {
                    if (++_landingChecks <= 8)
                        _events.ScheduleEvent(EVENT_CHECK_LANDING, 250ms);
                    continue;
                }
                _landingChecks = 0;
                int32 value = sSpellMgr->GetSpellInfo(706332)->Effects[EFFECT_1].CalcValue(owner) +
                              int32(owner->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.35f);
                if (owner->HasAura(705450))
                    value += owner->GetLevel() * 2;
                _me->CastCustomSpell(706332, SPELLVALUE_BASE_POINT1, value, target, TRIGGERED_FULL_MASK);
                _me->CastCustomSpell(706332, SPELLVALUE_BASE_POINT1, value, target, TRIGGERED_FULL_MASK);
                if (_called && owner->HasAura(500056))
                    for (Unit* enemy : Nearby(target, 6.0f))
                        if (owner->IsValidAttackTarget(enemy))
                            Cast(owner, enemy, 500564);
                _called = false;
                _me->AI()->AttackStart(target);
            }
            else if (event == EVENT_AUTO_LEAP)
            {
                if (Unit* target = _me->GetVictim())
                {
                    victim = target->GetGUID();
                    Leap();
                }
                else
                    _events.ScheduleEvent(EVENT_AUTO_LEAP, 1s);
            }
        }
    }

  private:
    Creature* _me;
    EventMap _events;
    uint8 _landingChecks = 0;
    bool _called = false;
};

struct npc_ascension_witch_hunter_pet : PetAI
{
    explicit npc_ascension_witch_hunter_pet(Creature* creature) : PetAI(creature), actions(creature) {}
    HoundActions actions;
    void SetGUID(ObjectGuid const& guid, int32 id) override
    {
        if (id == GUID_LEAP_TARGET)
            actions.victim = guid;
    }
    void DoAction(int32 action) override
    {
        if (action == ACTION_CALLED_LEAP)
            actions.Leap(true);
    }
    void UpdateAI(uint32 diff) override
    {
        actions.Update(diff);
        PetAI::UpdateAI(diff);
    }
};

struct npc_ascension_witch_hunter_hound : ScriptedAI
{
    explicit npc_ascension_witch_hunter_hound(Creature* creature) : ScriptedAI(creature), actions(creature) {}
    HoundActions actions;
    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? Owner(summoner->ToUnit()) : nullptr;
        if (!owner)
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetOwnerGUID(owner->GetGUID());
        me->SetFaction(owner->GetFaction());
        me->SetLevel(owner->GetLevel());
        me->SetReactState(REACT_DEFENSIVE);
        me->SetMaxHealth(std::max(1u, owner->CountPctFromMaxHealth(20)));
        me->SetFullHealth();
        me->GetMotionMaster()->MoveFollow(owner, 2.0f, PET_FOLLOW_ANGLE);
        if (Unit* victim = owner->GetVictim())
            AttackStart(victim);
    }
    void SetGUID(ObjectGuid const& guid, int32 id) override
    {
        if (id == GUID_LEAP_TARGET)
            actions.victim = guid;
    }
    void DoAction(int32 action) override
    {
        if (action == ACTION_CALLED_LEAP)
            actions.Leap(true);
    }
    void UpdateAI(uint32 diff) override
    {
        actions.Update(diff);
        if (me->GetVictim())
            DoMeleeAttackIfReady();
    }
};

struct npc_ascension_witch_hunter_field : ScriptedAI
{
    explicit npc_ascension_witch_hunter_field(Creature* creature) : ScriptedAI(creature) {}
    EventMap events;
    ObjectGuid ownerGuid;
    void AttackStart(Unit*) override {}
    void MoveInLineOfSight(Unit*) override {}
    void EnterEvadeMode(EvadeReason) override {}

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* owner = summoner ? Owner(summoner->ToUnit()) : nullptr;
        if (!owner)
        {
            me->DespawnOrUnsummon();
            return;
        }
        ownerGuid = owner->GetGUID();
        me->SetOwnerGUID(ownerGuid);
        me->SetFaction(owner->GetFaction());
        me->m_ControlledByPlayer = true;
        me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
        me->SetByteValue(UNIT_FIELD_BYTES_2, 1, owner->GetByteValue(UNIT_FIELD_BYTES_2, 1));
        me->SetLevel(owner->GetLevel());
        me->SetReactState(REACT_PASSIVE);
        me->SetImmuneToNPC(true);
        me->GetMotionMaster()->Clear();
        me->GetMotionMaster()->MoveIdle();
        if (me->GetEntry() == 50519)
        {
            me->CastSpell(me, 504854, true);
            me->CastSpell(me, 1108180, true);
        }
        events.ScheduleEvent(EVENT_FIELD_PULSE, me->GetEntry() >= 506250 ? 1s : 1ms);
    }

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (!events.ExecuteEvent())
            return;
        Player* owner = ObjectAccessor::GetPlayer(*me, ownerGuid);
        if (!owner || !owner->IsAlive() || !owner->IsInMap(me) || !owner->InSamePhase(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        me->SetByteValue(UNIT_FIELD_BYTES_2, 1, owner->GetByteValue(UNIT_FIELD_BYTES_2, 1));
        uint32 entry = me->GetEntry();
        if (entry == 254862)
        {
            float radius = sSpellMgr->GetSpellInfo(853203)->Effects[EFFECT_0].CalcRadius(owner);
            for (Unit* ally : Nearby(me, radius))
                if (ally == owner || owner->IsInPartyWith(ally))
                    ally->RemoveAurasWithMechanic((1 << MECHANIC_CHARM) | (1 << MECHANIC_FEAR) | (1 << MECHANIC_SLEEP),
                                                  AURA_REMOVE_BY_ENEMY_SPELL);
            events.ScheduleEvent(EVENT_FIELD_PULSE, 2500ms);
            return;
        }
        if (entry == 506010)
        {
            bool triggered = false;
            for (Unit* enemy : Nearby(me, 3.0f))
                if (owner->IsValidAttackTarget(enemy))
                {
                    Cast(owner, enemy, 504447);
                    Cast(owner, enemy, 504823);
                    triggered = true;
                }
            if (triggered)
            {
                me->DespawnOrUnsummon();
                return;
            }
        }
        else if (entry >= 506250 && entry <= 506253)
        {
            for (Unit* enemy : Nearby(me, 3.0f))
                if (owner->IsValidAttackTarget(enemy) && (entry != 506253 || (enemy->GetCreatureTypeMask() & 36)))
                {
                    if (entry == 506252)
                        Cast(owner, enemy, 681452);
                    else
                    {
                        uint32 count = 0;
                        SpellInfo const* stun = sSpellMgr->GetSpellInfo(681179);
                        uint32 limit = stun->MaxAffectedTargets;
                        float radius = entry == 506250 ? stun->Effects[EFFECT_0].CalcRadius(owner) : 5.0f;
                        for (Unit* victim : Nearby(enemy, radius))
                            if (owner->IsValidAttackTarget(victim))
                            {
                                if (entry == 506250 && limit && count++ >= limit)
                                    break;
                                if (entry == 506250)
                                {
                                    Cast(owner, victim, 681179);
                                    Cast(owner, victim, 681177);
                                }
                                else
                                    Cast(owner, victim, entry == 506251 ? 681447 : 681457);
                            }
                    }
                    me->DespawnOrUnsummon();
                    return;
                }
        }
        events.ScheduleEvent(EVENT_FIELD_PULSE, 250ms);
    }
};

class aura_ascension_witch_hunter_trap_launcher : public AuraScript
{
    PrepareAuraScript(aura_ascension_witch_hunter_trap_launcher);

    void Synchronize(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = Owner(GetTarget());
        if (player && player == GetTarget() && GetCaster() == player)
            SynchronizeAscensionTalentReplacements(player);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_witch_hunter_trap_launcher::Synchronize,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_witch_hunter_trap_launcher::Synchronize,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_witch_hunter_summon : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_summon);
    void Summon(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[index];
        PreventHitDefaultEffect(index);
        uint32 duration = uint32(std::max(1, GetSpellInfo()->GetDuration()));
        player->ApplySpellMod(GetSpellInfo()->Id, SPELLMOD_DURATION, duration);
        if (effect.MiscValue == 50224)
        {
            Unit* target = GetExplTargetUnit();
            if (!target || target == player)
                if (Unit* selected = player->GetSelectedUnit(); selected &&
                    player->HasInArc(float(M_PI), selected) && player->IsValidAttackTarget(selected))
                    target = selected;
            SummonHounds(player, std::max(1, effect.CalcValue(player)), duration, GetSpellInfo()->Id,
                         target);
            return;
        }
        Position position = player->GetPosition();
        if (WorldLocation const* destination = GetExplTargetDest())
            position = *destination;
        if (effect.MiscValue == 506010)
        {
            float const radius = effect.CalcRadius(player);
            for (int32 i = std::max(1, effect.CalcValue(player)); i > 0; --i)
                player->SummonCreature(effect.MiscValue, player->GetRandomPoint(position, radius),
                                       TEMPSUMMON_TIMED_DESPAWN, duration);
            return;
        }
        player->SummonCreature(effect.MiscValue, position, TEMPSUMMON_TIMED_DESPAWN, duration);
    }
    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_witch_hunter_summon::Summon, EFFECT_ALL, SPELL_EFFECT_SUMMON);
    }
};

class spell_ascension_witch_hunter_smoke : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_smoke);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({805757});
    }

    void ApplyFriendlySmoke(SpellEffIndex)
    {
        if (DynamicObject* cloud = GetCaster()->GetDynObject(GetSpellInfo()->Id))
        {
            SpellCastTargets targets;
            targets.SetDst(*cloud);
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_AURA_DURATION, cloud->GetDuration());
            GetCaster()->CastSpell(targets, sSpellMgr->GetSpellInfo(805757), &values, TRIGGERED_FULL_MASK);
        }
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_witch_hunter_smoke::ApplyFriendlySmoke, EFFECT_1,
                                    SPELL_EFFECT_PERSISTENT_AREA_AURA);
    }
};
}

void AddAscensionWitchHunterSummonScripts()
{
    RegisterCreatureAI(npc_ascension_witch_hunter_pet);
    RegisterCreatureAI(npc_ascension_witch_hunter_hound);
    RegisterCreatureAI(npc_ascension_witch_hunter_field);
    RegisterSpellScript(spell_ascension_witch_hunter_summon);
    RegisterSpellScript(aura_ascension_witch_hunter_trap_launcher);
    RegisterSpellScript(spell_ascension_witch_hunter_smoke);
}
