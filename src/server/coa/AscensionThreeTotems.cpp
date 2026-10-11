/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientSpellPatches.h"
#include "CellImpl.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>

namespace
{
constexpr uint32 SPELL_CHARGE_WINDUP = 256743;
constexpr uint32 SPELL_CHARGE_TRAIL = 256744;
constexpr uint32 SPELL_CHARGE_IMPACT = 256746;
constexpr uint32 SPELL_CHARGE_TELEGRAPH = 255356;
constexpr uint32 SPELL_CHARGE_TREMOR = 64228;
constexpr uint32 SPELL_ENRAGE = 256756;
constexpr uint32 SPELL_THUNDERCLAP = 8078;
constexpr uint32 SPELL_SLAM = 11430;
constexpr uint32 SPELL_GRIMTOTEM_DISGUISE_WARRIOR = 256709;
constexpr uint32 SPELL_GRIMTOTEM_DISGUISE_GUARD = 256710;

constexpr uint32 FACTION_MALGORM = 1027;

constexpr uint8 SAY_AGGRO = 0;
constexpr uint8 SAY_CHARGE = 1;
constexpr uint8 SAY_ENRAGE = 2;
constexpr uint8 SAY_LOW_HEALTH = 3;
constexpr uint8 SAY_KILL = 4;
constexpr uint8 SAY_DEATH = 5;

constexpr uint32 POINT_CHARGE_END = 1;
constexpr float CHARGE_RANGE = 30.0f;
constexpr float CHARGE_SPEED = 12.0f;
constexpr float CHARGE_MIN_RUN = 2.0f;
constexpr float WALL_TOLERANCE = 1.0f;
constexpr uint32 CHARGE_RUN_GRACE_MS = 1000;
constexpr uint32 TREMOR_PULSE_MS = 1000;
constexpr uint32 ENRAGE_HEALTH_PCT = 50;
constexpr int32 ENRAGE_MS = 10000;
constexpr uint32 LOW_HEALTH_PCT = 20;
constexpr float CORRUPTED_TOTEM_REACH = 5.5f;
constexpr uint32 NPC_TOTEM_CHANNEL_TARGET = 23033;
constexpr float TOTEM_CHANNEL_TARGET_HEIGHT = 1.5f;

enum MalgormEvents
{
    EVENT_MALGORM_CHARGE = 1,
    EVENT_MALGORM_THUNDERCLAP,
    EVENT_MALGORM_SLAM
};

class NearestGooberCastingSpell
{
public:
    NearestGooberCastingSpell(WorldObject const* origin, uint32 spellId, float range)
        : _origin(origin), _spellId(spellId), _range(range) { }

    bool operator()(GameObject* gameObject)
    {
        if (gameObject->GetGoType() != GAMEOBJECT_TYPE_GOOBER || gameObject->GetGOInfo()->goober.spellId != _spellId
            || !gameObject->isSpawned() || !_origin->IsWithinDistInMap(gameObject, _range))
            return false;

        _range = _origin->GetDistance(gameObject);
        return true;
    }

private:
    WorldObject const* _origin;
    uint32 _spellId;
    float _range;
};

GameObject* NearestCorruptibleTotem(Unit* corruptor, uint32 spellId)
{
    GameObject* totem = nullptr;
    NearestGooberCastingSpell check(corruptor, spellId, CORRUPTED_TOTEM_REACH);
    Acore::GameObjectLastSearcher<NearestGooberCastingSpell> searcher(corruptor, totem, check);
    Cell::VisitObjects(corruptor, searcher, CORRUPTED_TOTEM_REACH);
    return totem;
}
}

class spell_coa_corrupting_totem : public SpellScript
{
    PrepareSpellScript(spell_coa_corrupting_totem);

    SpellCastResult RequireTotemAtHand()
    {
        return NearestCorruptibleTotem(GetCaster(), GetSpellInfo()->Id) ? SPELL_CAST_OK : SPELL_FAILED_OUT_OF_RANGE;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_coa_corrupting_totem::RequireTotemAtHand);
    }
};

class spell_coa_corrupting_totem_aura : public AuraScript
{
    PrepareAuraScript(spell_coa_corrupting_totem_aura);

    void ChannelIntoTotem(AuraEffect const*, AuraEffectHandleModes)
    {
        GameObject* totem = NearestCorruptibleTotem(GetTarget(), GetId());
        if (!totem)
            return;

        Position spot = totem->GetPosition();
        spot.m_positionZ += TOTEM_CHANNEL_TARGET_HEIGHT;
        if (TempSummon* channelTarget = totem->SummonCreature(NPC_TOTEM_CHANNEL_TARGET, spot,
            TEMPSUMMON_TIMED_DESPAWN, uint32(std::max(GetAura()->GetDuration(), 0))))
        {
            _channelTarget = channelTarget->GetGUID();
            GetTarget()->SetGuidValue(UNIT_FIELD_CHANNEL_OBJECT, _channelTarget);
        }
    }

    void CorruptTotemOnCompletedChannel(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Creature* channelTarget = ObjectAccessor::GetCreature(*GetTarget(), _channelTarget))
            channelTarget->DespawnOrUnsummon();

        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;

        GameObject* totem = NearestCorruptibleTotem(GetTarget(), GetId());
        if (totem && totem->AI())
            totem->AI()->SpellHit(GetTarget(), GetSpellInfo());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_coa_corrupting_totem_aura::ChannelIntoTotem, EFFECT_0,
                                              SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_coa_corrupting_totem_aura::CorruptTotemOnCompletedChannel, EFFECT_0,
                                                SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }

    ObjectGuid _channelTarget;
};

struct npc_coa_malgorm_hollowhoof : public ScriptedAI
{
    explicit npc_coa_malgorm_hollowhoof(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _events.Reset();
        _enraged = false;
        _saidLowHealth = false;
        _saidCharge = false;
        _chargeRunMs = 0;
        _tremorPulseMs = 0;
        for (uint32 spell : { SPELL_CHARGE_TELEGRAPH, SPELL_CHARGE_TRAIL, SPELL_ENRAGE })
            me->RemoveAurasDueToSpell(spell);
        me->SetControlled(false, UNIT_STATE_ROOT);
    }

    void JustEngagedWith(Unit* who) override
    {
        Talk(SAY_AGGRO, who->GetCharmerOrOwnerPlayerOrPlayerItself());
        _events.ScheduleEvent(EVENT_MALGORM_CHARGE, 10s, 12s);
        _events.ScheduleEvent(EVENT_MALGORM_THUNDERCLAP, 7s, 9s);
        _events.ScheduleEvent(EVENT_MALGORM_SLAM, 4s, 6s);
    }

    void DamageTaken(Unit*, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (!_enraged && me->HealthBelowPctDamaged(ENRAGE_HEALTH_PCT, damage))
        {
            _enraged = true;
            Talk(SAY_ENRAGE);
            HoldFor(SPELL_ENRAGE, ENRAGE_MS);
        }

        if (!_saidLowHealth && me->HealthBelowPctDamaged(LOW_HEALTH_PCT, damage))
        {
            _saidLowHealth = true;
            Talk(SAY_LOW_HEALTH);
        }
    }

    void KilledUnit(Unit* victim) override
    {
        if (victim->IsPlayer())
            Talk(SAY_KILL);
    }

    void JustDied(Unit*) override
    {
        Talk(SAY_DEATH);
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        if (spell->Id == SPELL_CHARGE_WINDUP)
            RunCharge();
    }

    void OnSpellFailed(SpellInfo const* spell) override
    {
        if (spell->Id == SPELL_CHARGE_WINDUP)
            FinishCharge(false);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type == POINT_MOTION_TYPE && id == POINT_CHARGE_END && _chargeRunMs)
            FinishCharge(_chargeHitsWall);
    }

    void UpdateAI(uint32 diff) override
    {
        if (_tremorPulseMs)
            UpdateTremor(diff);

        if (_chargeRunMs)
        {
            UpdateChargeRun(diff);
            return;
        }

        if (!UpdateVictim())
            return;

        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        _events.Update(diff);

        switch (_events.ExecuteEvent())
        {
            case EVENT_MALGORM_CHARGE:
                BeginCharge();
                _events.Repeat(20s);
                return;
            case EVENT_MALGORM_THUNDERCLAP:
                DoCastSelf(SPELL_THUNDERCLAP);
                _events.Repeat(14s, 18s);
                return;
            case EVENT_MALGORM_SLAM:
                DoCastVictim(SPELL_SLAM);
                _events.Repeat(10s, 14s);
                return;
            default:
                break;
        }

        DoMeleeAttackIfReady();
    }

private:
    void BeginCharge()
    {
        Unit* target = SelectTarget(SelectTargetMethod::Random, 0, CHARGE_RANGE, true);
        if (!target)
            return;

        me->StopMoving();
        _chargeAngle = me->GetAngle(target);
        me->SetFacingTo(_chargeAngle);
        me->SetControlled(true, UNIT_STATE_ROOT);
        me->SetTarget();
        HoldFor(SPELL_CHARGE_TELEGRAPH, int32(sSpellMgr->AssertSpellInfo(SPELL_CHARGE_WINDUP)->CalcCastTime()));
        if (!_saidCharge || urand(0, 2) == 0)
        {
            _saidCharge = true;
            Talk(SAY_CHARGE);
        }
        DoCastSelf(SPELL_CHARGE_TREMOR, true);
        _tremorPulseMs = TREMOR_PULSE_MS;
        if (me->CastSpell(me, SPELL_CHARGE_WINDUP, false) != SPELL_CAST_OK)
            FinishCharge(false);
    }

    void UpdateTremor(uint32 diff)
    {
        if (_tremorPulseMs > diff)
        {
            _tremorPulseMs -= diff;
            return;
        }

        _tremorPulseMs = 0;
        if (me->FindCurrentSpellBySpellId(SPELL_CHARGE_WINDUP))
        {
            DoCastSelf(SPELL_CHARGE_TREMOR, true);
            _tremorPulseMs = TREMOR_PULSE_MS;
        }
    }

    void RunCharge()
    {
        me->RemoveAurasDueToSpell(SPELL_CHARGE_TELEGRAPH);
        me->SetOrientation(_chargeAngle);
        Position destination = me->GetPosition();
        me->MovePositionToFirstCollision(destination, CHARGE_RANGE, 0.0f);
        float const run = me->GetExactDist2d(&destination);
        _chargeHitsWall = run < CHARGE_RANGE - WALL_TOLERANCE;
        if (run < CHARGE_MIN_RUN)
        {
            FinishCharge(_chargeHitsWall);
            return;
        }

        _chargeRunMs = uint32(run / CHARGE_SPEED * IN_MILLISECONDS) + CHARGE_RUN_GRACE_MS;
        me->SetControlled(false, UNIT_STATE_ROOT);
        DoCastSelf(SPELL_CHARGE_TRAIL, true);
        me->GetMotionMaster()->MoveCharge(destination.GetPositionX(), destination.GetPositionY(),
            destination.GetPositionZ(), CHARGE_SPEED, POINT_CHARGE_END);
    }

    void UpdateChargeRun(uint32 diff)
    {
        if (_chargeRunMs > diff)
            _chargeRunMs -= diff;
        else
            FinishCharge(_chargeHitsWall);
    }

    void FinishCharge(bool hitWall)
    {
        _chargeRunMs = 0;
        _tremorPulseMs = 0;
        me->RemoveAurasDueToSpell(SPELL_CHARGE_TELEGRAPH);
        me->RemoveAurasDueToSpell(SPELL_CHARGE_TRAIL);
        me->SetControlled(false, UNIT_STATE_ROOT);
        if (hitWall)
            DoCastSelf(SPELL_CHARGE_IMPACT, true);
        if (Unit* victim = me->GetVictim())
            me->SetTarget(victim->GetGUID());
    }

    void HoldFor(uint32 spellId, int32 durationMs)
    {
        if (Aura* aura = me->AddAura(spellId, me))
        {
            aura->SetMaxDuration(durationMs);
            aura->SetDuration(durationMs);
        }
    }

    EventMap _events;
    bool _enraged = false;
    bool _saidLowHealth = false;
    bool _saidCharge = false;
    bool _chargeHitsWall = false;
    float _chargeAngle = 0.0f;
    uint32 _chargeRunMs = 0;
    uint32 _tremorPulseMs = 0;
};

class spell_coa_grimtotem_disguise : public AuraScript
{
    PrepareAuraScript(spell_coa_grimtotem_disguise);

    void ForceMalgormNeutral(AuraEffect const*, AuraEffectHandleModes)
    {
        SetMalgormNeutral(true);
    }

    void RestoreMalgorm(AuraEffect const*, AuraEffectHandleModes)
    {
        SetMalgormNeutral(false);
    }

    void SetMalgormNeutral(bool apply)
    {
        if (Player* player = GetTarget()->ToPlayer())
        {
            player->GetReputationMgr().ApplyForceReaction(FACTION_MALGORM, REP_NEUTRAL, apply);
            player->GetReputationMgr().SendForceReactions();
        }
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_coa_grimtotem_disguise::ForceMalgormNeutral, EFFECT_2,
            SPELL_AURA_FORCE_REACTION, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_coa_grimtotem_disguise::RestoreMalgorm, EFFECT_2,
            SPELL_AURA_FORCE_REACTION, AURA_EFFECT_HANDLE_REAL);
    }
};

void AddSC_AscensionThreeTotems()
{
    RegisterCreatureAI(npc_coa_malgorm_hollowhoof);
    RegisterSpellAndAuraScriptPair(spell_coa_corrupting_totem, spell_coa_corrupting_totem_aura);
    RegisterSpellScript(spell_coa_grimtotem_disguise);
    for (uint32 disguise : { SPELL_GRIMTOTEM_DISGUISE_WARRIOR, SPELL_GRIMTOTEM_DISGUISE_GUARD })
        Ascension::ClientSpellPatches::Instance().Register(disguise);
}
