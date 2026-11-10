#include "ScriptedCreature.h"
#include "CreatureScript.h"
#include "CreatureGroups.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Timer.h"
#include "TrainingDummyDefines.h"
#include "TrainingDummyImmunities.h"
#include <unordered_map>
#include <vector>

namespace
{
enum DummyEvents
{
    EVENT_MAINTENANCE = 1,
    EVENT_BOSS_SPELL,
    EVENT_BOSS_WARNING,
    EVENT_BOSS_HEAVY_HIT,
    EVENT_BOSS_CC_IMMUNE_END
};

enum DummyEntries
{
    DYNAMIC_EXECUTE = 666925,
    DYNAMIC_HEALING = 666935,
    DYNAMIC_CONFIGURABLE = 967171,
    DYNAMIC_TANK = 967182,
    DYNAMIC_TARGET = 967254,
    DYNAMIC_BOSS = 9780200
};

enum DummySpells
{
    SPELL_PRACTICE_SHADOW_BOLT = 9613,
    SPELL_BOSS_HOLOGRAM = 2180104
};
}

struct npc_advanced_training_dummy : ScriptedAI
{
    explicit npc_advanced_training_dummy(Creature* creature) : ScriptedAI(creature)
    {
        me->SetCombatMovement(false);
        me->SetReactState(REACT_PASSIVE);
        ApplyTrainingDummyMovementImmunity(me);
    }

    bool IsDynamic() const
    {
        return true;
    }

    bool IsBoss() const { return me->GetEntry() == DYNAMIC_BOSS; }
    bool IsTank() const { return me->GetEntry() == DYNAMIC_TANK || IsBoss(); }
    bool IsHealing() const { return me->GetEntry() == DYNAMIC_HEALING; }
    bool IsExecute() const { return me->GetEntry() == DYNAMIC_EXECUTE; }

    uint32 GetData(uint32 id) const override
    {
        return id == DATA_HEALING_PRACTICE_ACTIVE && IsHealing() && _healingEnabled;
    }

    void SetCrowdControlImmunity(bool enabled)
    {
        for (uint32 mechanic : {MECHANIC_CHARM, MECHANIC_DISORIENTED, MECHANIC_FEAR, MECHANIC_ROOT,
            MECHANIC_SLEEP, MECHANIC_STUN, MECHANIC_POLYMORPH, MECHANIC_HORROR, MECHANIC_SAPPED})
            me->ApplySpellImmune(DYNAMIC_CONFIGURABLE, IMMUNITY_MECHANIC, mechanic, enabled);
        _ccImmune = enabled;
    }

    void SetTrainingLevel(uint8 level)
    {
        me->SetLevel(level);
        CreatureTemplate resolved = *me->GetCreatureTemplate();
        if (IsDynamic())
            resolved.expansion = level > 70 ? 2 : (level > 60 ? 1 : 0);
        auto const* info = &resolved;
        auto const* stats = sObjectMgr->GetCreatureBaseStats(level, info->unit_class);
        me->SetCreateHealth(std::max<uint32>(100, stats->GenerateHealth(info)));
        me->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(me->GetCreateHealth()));
        me->SetStatFlatModifier(UNIT_MOD_ARMOR, BASE_VALUE, stats->GenerateArmor(info));
        me->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, float(stats->AttackPower));
        me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, stats->GenerateBaseDamage(info));
        me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, stats->GenerateBaseDamage(info) * 1.5f);
        me->UpdateAllStats();
        me->SetFullHealth();
    }

    void Reset() override
    {
        events.Reset();
        events.ScheduleEvent(EVENT_MAINTENANCE, 1s);
        _activity.clear();
        _owner.Clear();
        _healingEnabled = false;
        _vulnerable = true;
        _heavyPending = false;
        _ccPhase = false;
        SetTrainingDummyCrowdControlImmunity(me, !IsBoss());
        if (me->GetEntry() == DYNAMIC_CONFIGURABLE || IsBoss())
            SetCrowdControlImmunity(true);
        if (IsBoss())
            SetBossCounterImmunity(true);
        me->SetImmuneToPC(false);
        me->SetRegeneratingHealth(!IsExecute());
        SetTrainingLevel(IsDynamic() ? 1 : me->GetCreatureTemplate()->minlevel);
        EnsureBossVisual();
    }

    void MoveInLineOfSight(Unit*) override { }

    bool Engage(Unit* unit)
    {
        Player* player = unit ? unit->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        if (!player || !player->IsAlive() || !me->IsWithinDistInMap(player, 60.0f))
            return false;

        std::vector<npc_advanced_training_dummy*> targets{this};
        if (me->GetEntry() == DYNAMIC_TARGET && me->GetFormation())
            for (auto const& [member, info] : me->GetFormation()->GetMembers())
                if (member != me && member->GetEntry() == DYNAMIC_TARGET && member->IsAIEnabled
                    && member->GetScriptName() == me->GetScriptName())
                    targets.push_back(static_cast<npc_advanced_training_dummy*>(member->AI()));

        for (auto* target : targets)
            if (!target->_owner.IsEmpty() && target->_owner != player->GetGUID())
                return false;
        for (auto* target : targets)
        {
            if (target->_owner.IsEmpty())
            {
                target->_owner = player->GetGUID();
                target->SetTrainingLevel(target->IsBoss() ? player->GetLevel() + 3 : player->GetLevel());
                if (target->IsBoss())
                {
                    target->events.ScheduleEvent(EVENT_BOSS_WARNING, 12s);
                }
            }
            target->_activity[player->GetGUID()] = getMSTime();
        }
        if (unit != player)
            _activity[unit->GetGUID()] = getMSTime();
        me->SetInCombatWith(player);
        if (IsTank())
            me->Attack(player, true);
        return true;
    }

    void AttackStart(Unit* unit) override
    {
        if (!IsHealing() && _vulnerable)
            Engage(unit);
    }

    void JustEnteredCombat(Unit* unit) override
    {
        if (!IsHealing() && _vulnerable)
            Engage(unit);
    }

    void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (IsHealing() || !_vulnerable || !Engage(attacker))
        {
            damage = 0;
            return;
        }
        me->SetHealth(IsExecute() ? std::max<uint32>(2, me->CountPctFromMaxHealth(18)) : me->GetMaxHealth());
        damage = std::min(damage, me->GetHealth() - 1);
    }

    void HealReceived(Unit* healer, uint32& amount) override
    {
        if (!IsHealing())
            return;
        if (!_healingEnabled || !Engage(healer))
        {
            amount = 0;
            return;
        }
        me->SetHealth(std::max<uint32>(1, me->CountPctFromMaxHealth(50)));
    }

    void DamageDealt(Unit* victim, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (!IsTank() || !victim || victim->GetGUID() != _owner)
        {
            damage = 0;
            return;
        }
        if (damage >= victim->GetHealth())
        {
            damage = victim->GetHealth() > 1 ? victim->GetHealth() - 1 : 0;
            me->AttackStop();
            _activity.clear();
        }
    }

    void ReceiveEmote(Player* player, uint32 emote) override
    {
        if (!me->IsWithinDistInMap(player, 10.0f) || !me->IsWithinLOSInMap(player))
            return;
        if (IsTank() && emote == TEXT_EMOTE_POKE && _owner == player->GetGUID())
        {
            me->CombatStop(true);
            me->RemoveAllAuras();
            Reset();
            return;
        }
        if (IsHealing() && emote == TEXT_EMOTE_POKE)
        {
            if (!_owner.IsEmpty() && _owner != player->GetGUID())
                return;
            _healingEnabled = !_healingEnabled;
            if (_healingEnabled)
                SetTrainingLevel(player->GetLevel());
            if (!_healingEnabled)
            {
                me->CombatStop(true);
                me->RemoveAllAuras();
                _activity.clear();
                _owner.Clear();
                SetTrainingLevel(1);
            }
            me->SetHealth(_healingEnabled ? me->CountPctFromMaxHealth(50) : me->GetMaxHealth());
            me->Whisper(_healingEnabled ? "Healing practice enabled." : "Healing practice stopped.", LANG_UNIVERSAL, player);
            return;
        }
        if (me->GetEntry() != DYNAMIC_CONFIGURABLE)
            return;
        if (emote == TEXT_EMOTE_CURIOUS || emote == TEXT_EMOTE_WAVE)
        {
            me->Whisper("/poke: vulnerability. In combat: /agree or /no: level. Crowd control immunity is always enabled.",
                LANG_UNIVERSAL, player);
        }
        else if (emote == TEXT_EMOTE_POKE && !me->IsInCombat())
        {
            _vulnerable = !_vulnerable;
            me->SetImmuneToPC(!_vulnerable);
        }
        else if (_owner == player->GetGUID() && me->IsInCombat())
        {
            if (emote == TEXT_EMOTE_AGREE && me->GetLevel() < 83)
                SetTrainingLevel(me->GetLevel() + 1);
            else if (emote == TEXT_EMOTE_NO && me->GetLevel() > 1)
                SetTrainingLevel(me->GetLevel() - 1);
            else if (emote == TEXT_EMOTE_CLAP)
            {
                me->Whisper("Crowd control immunity is always enabled.", LANG_UNIVERSAL, player);
            }
        }
    }

    void UpdateAI(uint32 diff) override
    {
        if (!UpdateBossSession())
            return;
        events.Update(diff);
        uint32 const event = events.ExecuteEvent();
        if (event == EVENT_MAINTENANCE)
        {
            MaintainSession();
            events.ScheduleEvent(EVENT_MAINTENANCE, 1s);
        }
        else if (IsBoss() && event)
            HandleBossEvent(event);
        if (IsTank() && !_owner.IsEmpty() && !_activity.empty() && !_heavyPending)
            DoMeleeAttackIfReady();
    }

private:
    bool UpdateBossSession()
    {
        if (IsBoss() && !_owner.IsEmpty())
        {
            Player* owner = ObjectAccessor::GetPlayer(*me, _owner);
            if (!owner || !owner->IsAlive() || !me->IsWithinDistInMap(owner, 60.0f) || _activity.empty())
            {
                me->InterruptNonMeleeSpells(true);
                me->CombatStop(true);
                me->RemoveAllAuras();
                Reset();
                return false;
            }
            if (_heavyPending && (me->HasAuraType(SPELL_AURA_MOD_STUN)
                || me->HasAuraType(SPELL_AURA_MOD_DISARM)))
            {
                _heavyPending = false;
                events.CancelEvent(EVENT_BOSS_HEAVY_HIT);
                SetBossCounterImmunity(true);
                me->Whisper("Heavy strike stopped!", LANG_UNIVERSAL, owner);
                BeginBossImmunity(owner);
            }
        }
        return true;
    }

    void MaintainSession()
    {
        std::vector<ObjectGuid> untracked;
        for (auto const& [guid, reference] : me->GetCombatManager().GetPvECombatRefs())
            if (_activity.find(guid) == _activity.end())
                untracked.push_back(guid);
        for (ObjectGuid const& guid : untracked)
        {
            auto const& refs = me->GetCombatManager().GetPvECombatRefs();
            if (auto ref = refs.find(guid); ref != refs.end())
                ref->second->EndCombat();
        }
        for (auto itr = _activity.begin(); itr != _activity.end();)
        {
            Unit* unit = ObjectAccessor::GetUnit(*me, itr->first);
            if (!unit || !unit->IsAlive() || !me->IsWithinDistInMap(unit, 60.0f)
                || (!(IsTank() && itr->first == _owner)
                    && getMSTimeDiff(itr->second, getMSTime()) >= 15 * IN_MILLISECONDS))
            {
                auto const& refs = me->GetCombatManager().GetPvECombatRefs();
                if (auto ref = refs.find(itr->first); ref != refs.end())
                    ref->second->EndCombat();
                itr = _activity.erase(itr);
            }
            else
                ++itr;
        }
        if (_activity.empty() && (me->IsInCombat() || !_owner.IsEmpty() || me->GetHealth() != me->GetMaxHealth()))
        {
            me->CombatStop(true);
            me->RemoveAllAuras();
            _owner.Clear();
            if (me->GetEntry() == DYNAMIC_CONFIGURABLE)
                SetCrowdControlImmunity(true);
            SetTrainingLevel(IsDynamic() ? 1 : me->GetCreatureTemplate()->minlevel);
            if (IsHealing() && _healingEnabled)
                me->SetHealth(me->CountPctFromMaxHealth(50));
        }
        EnsureBossVisual();
    }

    void EnsureBossVisual()
    {
        if (IsBoss() && !me->HasAura(SPELL_BOSS_HOLOGRAM))
            me->AddAura(SPELL_BOSS_HOLOGRAM, me);
    }

    void SetBossCounterImmunity(bool enabled)
    {
        for (uint32 mechanic : {MECHANIC_STUN, MECHANIC_DISARM})
            me->ApplySpellImmune(DYNAMIC_CONFIGURABLE, IMMUNITY_MECHANIC, mechanic, enabled);
    }

    void BeginBossImmunity(Player* owner)
    {
        if (_ccPhase)
            return;
        _ccPhase = true;
        SetTrainingDummyCrowdControlImmunity(me, true);
        me->Whisper("CC IMMUNITY: immune to all crowd control for 10 seconds!", LANG_UNIVERSAL, owner, true);
        events.ScheduleEvent(EVENT_BOSS_CC_IMMUNE_END, 10s);
    }

    void HandleBossEvent(uint32 event)
    {
        Player* owner = ObjectAccessor::GetPlayer(*me, _owner);
        if (!owner)
            return;
        switch (event)
        {
            case EVENT_BOSS_CC_IMMUNE_END:
                _ccPhase = false;
                SetTrainingDummyCrowdControlImmunity(me, false);
                me->Whisper("CC immunity ended! Shadow Bolt incoming - INTERRUPT!",
                    LANG_UNIVERSAL, owner, true);
                [[fallthrough]];
            case EVENT_BOSS_SPELL:
                if (_heavyPending || me->HasUnitState(UNIT_STATE_CASTING | UNIT_STATE_STUNNED)
                    || me->IsSpellProhibited(SPELL_SCHOOL_MASK_SHADOW))
                {
                    events.ScheduleEvent(EVENT_BOSS_SPELL, 1s);
                    break;
                }
                me->CastCustomSpell(SPELL_PRACTICE_SHADOW_BOLT, SPELLVALUE_BASE_POINT0,
                    int32(me->GetWeaponDamageRange(BASE_ATTACK, MAXDAMAGE) * 2.0f), owner,
                    TRIGGERED_IGNORE_POWER_AND_REAGENT_COST);
                events.ScheduleEvent(EVENT_BOSS_WARNING, 6s);
                break;
            case EVENT_BOSS_WARNING:
                if (_ccPhase || me->HasUnitState(UNIT_STATE_CASTING | UNIT_STATE_STUNNED))
                {
                    events.ScheduleEvent(EVENT_BOSS_WARNING, 1s);
                    break;
                }
                _heavyPending = true;
                SetBossCounterImmunity(false);
                me->Whisper("Heavy strike in 3 seconds! STUN or DISARM to stop it!", LANG_UNIVERSAL, owner, true);
                events.ScheduleEvent(EVENT_BOSS_HEAVY_HIT, 3s);
                break;
            case EVENT_BOSS_HEAVY_HIT:
                if (_heavyPending && me->IsWithinMeleeRange(owner)
                    && !me->HasAuraType(SPELL_AURA_MOD_STUN) && !me->HasAuraType(SPELL_AURA_MOD_DISARM))
                {
                    float const multiplier = me->GetPctModifierValue(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT);
                    me->SetStatPctModifier(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT, multiplier * 3.0f);
                    me->AttackerStateUpdate(owner, BASE_ATTACK);
                    me->SetStatPctModifier(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT, multiplier);
                    me->resetAttackTimer(BASE_ATTACK);
                }
                _heavyPending = false;
                SetBossCounterImmunity(true);
                BeginBossImmunity(owner);
                break;
            default:
                break;
        }
    }

    std::unordered_map<ObjectGuid, uint32> _activity;
    ObjectGuid _owner;
    bool _healingEnabled = false;
    bool _vulnerable = true;
    bool _ccImmune = true;
    bool _heavyPending = false;
    bool _ccPhase = false;
};

void AddSC_advanced_training_dummy()
{
    RegisterCreatureAI(npc_advanced_training_dummy);
}
