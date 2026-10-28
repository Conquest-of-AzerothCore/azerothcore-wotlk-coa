/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Chat.h"
#include "GameObject.h"
#include "GameObjectScript.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <algorithm>
#include <array>

namespace
{
constexpr uint32 ITEM_REPAIRED_CELLAR_KEY = 559141;
constexpr uint32 QUEST_A_QUIET_LIFE = 200081;

constexpr uint32 NPC_PROGENY_COPY = 9300259;
constexpr uint32 SPELL_FLAME_BREATH = 256748;
constexpr uint32 SPELL_CONE_TELEGRAPH = 354902;
constexpr uint32 MODEL_INVISIBLE = 11686;
constexpr uint8 SAY_NEAR_DEATH = 0;
constexpr uint32 SPLIT_HEALTH_PCT = 30;
constexpr uint32 NEAR_DEATH_HEALTH_PCT = 5;
constexpr uint32 BREATH_AIM_HOLD_MS = 2000;
constexpr uint32 CONE_TELEGRAPH_DECAY_MS = 1000;
constexpr int32 FLAME_BREATH_TICKS = 4;
constexpr uint32 FLAME_BREATH_TICK_MS = 500;

enum ProgenyEvents
{
    EVENT_FLAME_BREATH = 1,
    EVENT_SPLIT
};

std::array<Position, 4> const CopySpots =
{ {
    { 1935.89f, 1957.86f, 148.652f, 3.14f },
    { 1931.89f, 1961.86f, 148.653f, 4.71f },
    { 1927.89f, 1957.86f, 148.653f, 0.0f },
    { 1931.89f, 1953.86f, 148.653f, 1.57f }
} };
}

class go_coa_cain_cellar_door : public GameObjectScript
{
public:
    go_coa_cain_cellar_door() : GameObjectScript("go_coa_cain_cellar_door") { }

    bool OnGossipHello(Player* player, GameObject*) override
    {
        if (player->HasItemCount(ITEM_REPAIRED_CELLAR_KEY, 1))
            return false;

        ChatHandler(player->GetSession()).SendNotification("The door is locked.");
        return true;
    }
};

class go_coa_deathknell_hidden_statue : public GameObjectScript
{
public:
    go_coa_deathknell_hidden_statue() : GameObjectScript("go_coa_deathknell_hidden_statue") { }

    bool OnGossipHello(Player* player, GameObject*) override
    {
        QuestStatus status = player->GetQuestStatus(QUEST_A_QUIET_LIFE);
        return status == QUEST_STATUS_NONE || status == QUEST_STATUS_REWARDED;
    }
};

struct npc_coa_aberrant_progeny : public ScriptedAI
{
    explicit npc_coa_aberrant_progeny(Creature* creature) : ScriptedAI(creature), _copies(creature) { }

    void Reset() override
    {
        _events.Reset();
        _isHidden = false;
        _copies.DespawnAll();
        _hasSplit = false;
        _saidNearDeath = false;
        _breathHoldMs = 0;
        _breathTicksLeft = 0;
        Reappear();
    }

    void JustEngagedWith(Unit*) override
    {
        _events.ScheduleEvent(EVENT_FLAME_BREATH, 6s, 8s);
    }

    void DamageTaken(Unit*, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (_isHidden)
        {
            damage = 0;
            return;
        }

        if (!_hasSplit && me->HealthBelowPctDamaged(SPLIT_HEALTH_PCT, damage))
        {
            damage = std::min<uint32>(damage, me->GetHealth() - 1);
            Vanish();
            return;
        }

        if (!_saidNearDeath && me->HealthBelowPctDamaged(NEAR_DEATH_HEALTH_PCT, damage))
        {
            _saidNearDeath = true;
            Talk(SAY_NEAR_DEATH);
        }
    }

    void OnSpellStart(SpellInfo const* spell) override
    {
        if (spell->Id != SPELL_FLAME_BREATH)
            return;

        if (Spell* breath = me->GetCurrentSpell(CURRENT_GENERIC_SPELL))
            me->FocusTarget(breath, me);
    }

    void OnSpellCast(SpellInfo const* spell) override
    {
        if (spell->Id != SPELL_FLAME_BREATH || _breathHoldMs)
            return;

        _breathHoldMs = BREATH_AIM_HOLD_MS;
        _breathTicksLeft = FLAME_BREATH_TICKS - 1;
        _breathTickMs = FLAME_BREATH_TICK_MS;
    }

    void OnSpellFailed(SpellInfo const* spell) override
    {
        if (spell->Id == SPELL_FLAME_BREATH)
            ReleaseBreathAim();
    }

    void JustSummoned(Creature* summon) override
    {
        _copies.Summon(summon);
        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 60.0f, true))
            summon->AI()->AttackStart(target);
    }

    void SummonedCreatureDies(Creature* summon, Unit*) override
    {
        ForgetCopy(summon);
    }

    void SummonedCreatureDespawn(Creature* summon) override
    {
        ForgetCopy(summon);
    }

    void JustDied(Unit*) override
    {
        _copies.DespawnAll();
    }

    void UpdateAI(uint32 diff) override
    {
        if (me->HasUnitState(UNIT_STATE_CASTING))
            return;

        if (_breathHoldMs)
        {
            HoldBreathAim(diff);
            return;
        }

        if (!UpdateVictim())
            return;

        _events.Update(diff);

        switch (_events.ExecuteEvent())
        {
            case EVENT_FLAME_BREATH:
                BreatheFlame();
                _events.Repeat(14s, 16s);
                return;
            case EVENT_SPLIT:
                for (Position const& spot : CopySpots)
                    me->SummonCreature(NPC_PROGENY_COPY, spot, TEMPSUMMON_CORPSE_TIMED_DESPAWN, 3000);
                if (_copies.empty())
                    Return();
                return;
            default:
                break;
        }

        if (!_isHidden)
            DoMeleeAttackIfReady();
    }

private:
    void BreatheFlame()
    {
        if (Unit* victim = me->GetVictim())
        {
            me->StopMoving();
            me->SetFacingToObject(victim);
        }

        me->SetControlled(true, UNIT_STATE_ROOT);
        me->SetTarget();
        DoCastSelf(SPELL_CONE_TELEGRAPH, true);
        int32 tickDamage = BreathTickBasePoints();
        if (me->CastCustomSpell(SPELL_FLAME_BREATH, SPELLVALUE_BASE_POINT0, tickDamage, me) != SPELL_CAST_OK)
            ReleaseBreathAim();
    }

    static int32 BreathTickBasePoints()
    {
        SpellEffectInfo const& damage = sSpellMgr->AssertSpellInfo(SPELL_FLAME_BREATH)->Effects[EFFECT_0];
        int32 averageRoll = (damage.DieSides + 1) / 2;
        return std::max(1, (damage.BasePoints + averageRoll) / FLAME_BREATH_TICKS - averageRoll);
    }

    void HoldBreathAim(uint32 diff)
    {
        if (_breathTicksLeft)
        {
            if (_breathTickMs > diff)
            {
                _breathTickMs -= diff;
            }
            else
            {
                --_breathTicksLeft;
                _breathTickMs = FLAME_BREATH_TICK_MS;
                me->CastCustomSpell(SPELL_FLAME_BREATH, SPELLVALUE_BASE_POINT0, BreathTickBasePoints(), me,
                    TRIGGERED_FULL_MASK);
            }
        }

        if (_breathHoldMs > diff)
        {
            _breathHoldMs -= diff;
            if (_breathHoldMs <= CONE_TELEGRAPH_DECAY_MS)
                me->RemoveAurasDueToSpell(SPELL_CONE_TELEGRAPH);
            return;
        }

        ReleaseBreathAim();
    }

    void ReleaseBreathAim()
    {
        _breathHoldMs = 0;
        _breathTicksLeft = 0;
        me->RemoveAurasDueToSpell(SPELL_CONE_TELEGRAPH);
        me->SetControlled(false, UNIT_STATE_ROOT);
        if (Unit* victim = me->GetVictim())
            me->SetTarget(victim->GetGUID());
    }

    void Vanish()
    {
        _hasSplit = true;
        _isHidden = true;
        _events.CancelEvent(EVENT_FLAME_BREATH);
        _breathHoldMs = 0;
        me->InterruptNonMeleeSpells(true);
        me->RemoveAllAuras();
        me->AttackStop();
        me->SetReactState(REACT_PASSIVE);
        me->SetControlled(true, UNIT_STATE_ROOT);
        me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        me->SetDisplayId(MODEL_INVISIBLE);
        _events.ScheduleEvent(EVENT_SPLIT, 3s);
    }

    void ForgetCopy(Creature* summon)
    {
        _copies.Despawn(summon);
        if (_isHidden && _copies.empty())
            Return();
    }

    void Return()
    {
        _isHidden = false;
        Reappear();
        _events.ScheduleEvent(EVENT_FLAME_BREATH, 4s, 6s);
    }

    void Reappear()
    {
        me->SetDisplayId(me->GetNativeDisplayId(), me->GetNativeObjectScale());
        me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        me->SetControlled(false, UNIT_STATE_ROOT);
        me->SetReactState(REACT_AGGRESSIVE);
    }

    EventMap _events;
    SummonList _copies;
    bool _hasSplit = false;
    bool _isHidden = false;
    bool _saidNearDeath = false;
    uint32 _breathHoldMs = 0;
    uint32 _breathTickMs = 0;
    int32 _breathTicksLeft = 0;
};

void AddSC_AscensionCainManor()
{
    new go_coa_cain_cellar_door();
    new go_coa_deathknell_hidden_statue();
    RegisterCreatureAI(npc_coa_aberrant_progeny);
}
