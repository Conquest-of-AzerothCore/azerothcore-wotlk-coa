/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Containers.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "StringConvert.h"
#include "Tokenize.h"
#include "Unit.h"
#include "UnitScript.h"
#include "AllCreatureScript.h"
#include "Creature.h"
#include "Pet.h"
#include "PetScript.h"
#include "WorldScript.h"
#include <algorithm>
#include <array>
#include <mutex>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
enum class ProcEvent : uint8
{
    Cast,
    Hit,
    Damage,
    DirectDamage,
    PeriodicDamage,
    Heal,
    DirectHeal,
    PeriodicHeal,
    CriticalDamage,
    CriticalHeal,
    Critical,
    Kill,
    Parry,
    Dodged,
    AutoAttack,
    Damaged
};

std::unordered_map<std::string_view, ProcEvent> const EVENTS = {
    {"cast", ProcEvent::Cast}, {"hit", ProcEvent::Hit}, {"damage", ProcEvent::Damage},
    {"direct_damage", ProcEvent::DirectDamage}, {"periodic_damage", ProcEvent::PeriodicDamage},
    {"heal", ProcEvent::Heal}, {"direct_heal", ProcEvent::DirectHeal}, {"periodic_heal", ProcEvent::PeriodicHeal},
    {"critical_damage", ProcEvent::CriticalDamage}, {"critical_heal", ProcEvent::CriticalHeal},
    {"critical", ProcEvent::Critical}, {"kill", ProcEvent::Kill}, {"parry", ProcEvent::Parry},
    {"dodged", ProcEvent::Dodged}, {"auto_attack", ProcEvent::AutoAttack}, {"damaged", ProcEvent::Damaged}};

struct Condition
{
    enum class Kind : uint8
    {
        Power,
        Health,
        TargetHealth,
        TargetHealthBefore,
        Stacks,
        TargetStacks,
        TargetOutOfCombat
    };

    Kind What = Kind::Power;
    uint32 Aura = 0;
    std::string_view Op;
    int32 Value = 0;
};

struct EffectRule
{
    ProcEvent Event = ProcEvent::Cast;
    uint32 SchoolMask = 0;
    std::unordered_set<uint32> Spells;
    std::vector<uint32> RequiresAura;
    std::vector<uint32> TargetAura;
    std::vector<Condition> Conditions;
    std::vector<uint32> ConsumeAura;
    float Chance = 100.0f;
    Milliseconds Cooldown = 0ms;
    std::vector<uint32> TriggerSpells;
    float AmountPct = 0.0f;
    float ChancePerCombo = 0.0f;
};

struct AuraLink
{
    uint32 Enchant = 0;
    uint32 Grant = 0;
};

struct MinionAura
{
    uint32 Enchant = 0;
    uint32 Entry = 0;
    uint32 Aura = 0;
};
std::vector<MinionAura> MinionAuras;

void SyncMinionAuras(Unit* owner, Unit* minion)
{
    for (MinionAura const& listener : MinionAuras)
    {
        if (listener.Entry && minion->GetEntry() != listener.Entry)
            continue;
        if (!owner->HasAura(listener.Enchant))
            minion->RemoveAurasDueToSpell(listener.Aura);
        else if (!minion->HasAura(listener.Aura))
            minion->AddAura(listener.Aura, minion);
    }
}

void SyncMinionAuras(Unit* owner)
{
    for (Unit* minion : owner->m_Controlled)
        if (minion && minion->IsInWorld())
            SyncMinionAuras(owner, minion);
}

bool HasMinionAura(uint32 enchant)
{
    return std::any_of(MinionAuras.begin(), MinionAuras.end(),
        [enchant](MinionAura const& listener) { return listener.Enchant == enchant; });
}

constexpr AuraType SPELL_AURA_ASCENSION_PROC_TRIGGER_PCT = AuraType(354);

std::unordered_map<uint32, std::array<std::vector<EffectRule const*>, MAX_SPELL_EFFECTS>> Rules;
std::vector<EffectRule> Storage;
std::unordered_map<uint32, std::vector<AuraLink>> Links;

struct LastHit
{
    ObjectGuid Attacker;
    uint32 Spell = 0;
    uint32 SchoolMask = 0;
};
std::unordered_map<ObjectGuid, LastHit> LastHits;
std::mutex LastHitsLock;

std::string_view const OPS[] = {">=", "<=", "!=", ">", "<", "="};

bool Compare(int32 value, std::string_view op, int32 wanted)
{
    if (op == ">=") return value >= wanted;
    if (op == "<=") return value <= wanted;
    if (op == "!=") return value != wanted;
    if (op == ">") return value > wanted;
    if (op == "<") return value < wanted;
    return value == wanted;
}

Optional<Condition> ParseCondition(std::string_view text)
{
    static std::unordered_map<std::string_view, Condition::Kind> const KINDS = {
        {"power", Condition::Kind::Power}, {"health", Condition::Kind::Health},
        {"target_health", Condition::Kind::TargetHealth},
        {"target_health_before", Condition::Kind::TargetHealthBefore},
        {"stacks", Condition::Kind::Stacks}, {"target_stacks", Condition::Kind::TargetStacks},
        {"target_out_of_combat", Condition::Kind::TargetOutOfCombat}};

    Condition condition;
    if (text == "target_out_of_combat")
    {
        condition.What = Condition::Kind::TargetOutOfCombat;
        return condition;
    }
    for (std::string_view op : OPS)
    {
        std::size_t const at = text.find(op);
        if (at == std::string_view::npos)
            continue;
        std::string_view name = text.substr(0, at);
        Optional<int32> value = Acore::StringTo<int32>(text.substr(at + op.size()));
        if (std::size_t const colon = name.find(':'); colon != std::string_view::npos)
        {
            Optional<uint32> aura = Acore::StringTo<uint32>(name.substr(colon + 1));
            if (!aura)
                return {};
            condition.Aura = *aura;
            name = name.substr(0, colon);
        }
        auto const kind = KINDS.find(name);
        if (kind == KINDS.end() || !value)
            return {};
        condition.What = kind->second;
        condition.Op = op;
        condition.Value = *value;
        return condition;
    }
    return {};
}

int32 HealthPct(Unit const* unit, int64 offset = 0)
{
    if (!unit || !unit->GetMaxHealth())
        return 0;
    return int32((int64(unit->GetHealth()) + offset) * 100 / int64(unit->GetMaxHealth()));
}

int32 Stacks(Unit const* unit, uint32 aura, ObjectGuid caster = ObjectGuid::Empty)
{
    Aura const* found = unit ? unit->GetAura(aura, caster) : nullptr;
    if (!found)
        return 0;
    return found->GetStackAmount() > 1 || !found->GetCharges() ? found->GetStackAmount() : found->GetCharges();
}

std::pair<Unit*, Unit*> Sides(Unit* owner, ProcEventInfo& eventInfo)
{
    Unit* actor = eventInfo.GetActor();
    if (actor != owner)
        return { owner, actor };
    Unit* target = eventInfo.GetActionTarget();
    if (!target)
        if (Spell const* spell = eventInfo.GetProcSpell())
            target = spell->m_targets.GetUnitTarget();
    return { owner, target };
}

bool Holds(Condition const& condition, Unit* owner, ProcEventInfo& eventInfo)
{
    auto const [actor, target] = Sides(owner, eventInfo);
    switch (condition.What)
    {
        case Condition::Kind::Power:
        {
            if (!actor)
                return false;
            Powers const power = actor->getPowerType();
            int32 value = actor->GetPower(power);
            if (power == POWER_RAGE || power == POWER_RUNIC_POWER)
                value /= 10;
            return Compare(value, condition.Op, condition.Value);
        }
        case Condition::Kind::Health:
            return actor && Compare(HealthPct(actor), condition.Op, condition.Value);
        case Condition::Kind::TargetHealth:
            return target && Compare(HealthPct(target), condition.Op, condition.Value);
        case Condition::Kind::TargetHealthBefore:
        {
            HealInfo const* heal = eventInfo.GetHealInfo();
            int64 const healed = heal ? int64(heal->GetEffectiveHeal()) : 0;
            return target && Compare(HealthPct(target, -healed), condition.Op, condition.Value);
        }
        case Condition::Kind::Stacks:
            return Compare(Stacks(actor, condition.Aura), condition.Op, condition.Value);
        case Condition::Kind::TargetStacks:
            return actor && Compare(Stacks(target, condition.Aura, actor->GetGUID()), condition.Op, condition.Value);
        case Condition::Kind::TargetOutOfCombat:
            return target && !target->IsInCombat();
    }
    return false;
}

bool TargetsEnemy(SpellInfo const* trigger)
{
    return trigger->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY;
}

bool Periodic(ProcEventInfo const& eventInfo)
{
    return eventInfo.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
}

bool Dealt(ProcEventInfo const& eventInfo)
{
    DamageInfo const* damage = eventInfo.GetDamageInfo();
    return damage && damage->GetDamage() + damage->GetAbsorb() > 0;
}

bool Healed(ProcEventInfo const& eventInfo)
{
    HealInfo const* heal = eventInfo.GetHealInfo();
    return heal && heal->GetHeal() > 0;
}

bool Landed(ProcEventInfo const& eventInfo)
{
    return (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) || Periodic(eventInfo);
}

bool Critical(ProcEventInfo const& eventInfo)
{
    return eventInfo.GetHitMask() & PROC_HIT_CRITICAL;
}

bool HasAny(Unit const* unit, std::vector<uint32> const& auras, ObjectGuid caster = ObjectGuid::Empty)
{
    return unit && std::any_of(auras.begin(), auras.end(),
        [unit, caster](uint32 aura) { return unit->HasAura(aura, caster); });
}

bool Conditions(EffectRule const& rule, Unit* owner, ProcEventInfo& eventInfo)
{
    auto const [actor, target] = Sides(owner, eventInfo);
    if (!rule.RequiresAura.empty() && !HasAny(actor, rule.RequiresAura))
        return false;
    if (!rule.TargetAura.empty() && !(actor && HasAny(target, rule.TargetAura, actor->GetGUID())))
        return false;
    return std::all_of(rule.Conditions.begin(), rule.Conditions.end(),
        [owner, &eventInfo](Condition const& condition) { return Holds(condition, owner, eventInfo); });
}

bool KillingBlowMatches(EffectRule const& rule, ProcEventInfo& eventInfo)
{
    if (rule.Spells.empty() && !rule.SchoolMask)
        return true;
    Unit* actor = eventInfo.GetActor();
    Unit* victim = eventInfo.GetActionTarget();
    std::lock_guard<std::mutex> lock(LastHitsLock);
    auto const itr = victim ? LastHits.find(victim->GetGUID()) : LastHits.end();
    if (!actor || itr == LastHits.end() || itr->second.Attacker != actor->GetGUID())
        return false;
    return (rule.Spells.empty() || rule.Spells.contains(itr->second.Spell)) &&
        (!rule.SchoolMask || (itr->second.SchoolMask & rule.SchoolMask));
}

bool Matches(EffectRule const& rule, Unit* owner, ProcEventInfo& eventInfo)
{
    if (!Conditions(rule, owner, eventInfo))
        return false;
    if (rule.Event == ProcEvent::Kill)
    {
        if (!(eventInfo.GetTypeMask() & PROC_FLAG_KILL))
            return false;
        Player* player = eventInfo.GetActor() ? eventInfo.GetActor()->ToPlayer() : nullptr;
        return player && eventInfo.GetActionTarget() && player->isHonorOrXPTarget(eventInfo.GetActionTarget()) &&
            KillingBlowMatches(rule, eventInfo);
    }
    if (rule.Event == ProcEvent::Parry)
        return (eventInfo.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS)) &&
            (eventInfo.GetHitMask() & PROC_HIT_PARRY);
    if (rule.Event == ProcEvent::AutoAttack)
        return (eventInfo.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) &&
            (eventInfo.GetHitMask() & (PROC_HIT_NORMAL | PROC_HIT_CRITICAL));
    if (rule.Event == ProcEvent::Damaged)
        return (eventInfo.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS |
            PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_RANGED_DMG_CLASS)) && Dealt(eventInfo);
    if (rule.Event == ProcEvent::Dodged)
        return (eventInfo.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS)) &&
            (eventInfo.GetHitMask() & PROC_HIT_DODGE);

    SpellInfo const* spell = eventInfo.GetSpellInfo();
    if (!spell)
        return false;
    if (!rule.Spells.empty() && !rule.Spells.contains(spell->Id))
        return false;
    if (rule.SchoolMask && !(spell->GetSchoolMask() & rule.SchoolMask))
        return false;

    switch (rule.Event)
    {
        case ProcEvent::Cast:
            return eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST;
        case ProcEvent::Hit:
            return eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT;
        case ProcEvent::Damage:
            return Landed(eventInfo) && Dealt(eventInfo);
        case ProcEvent::DirectDamage:
            return !Periodic(eventInfo) && (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) && Dealt(eventInfo);
        case ProcEvent::PeriodicDamage:
            return Periodic(eventInfo) && Dealt(eventInfo);
        case ProcEvent::Heal:
            return Landed(eventInfo) && Healed(eventInfo);
        case ProcEvent::DirectHeal:
            return !Periodic(eventInfo) && (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) && Healed(eventInfo);
        case ProcEvent::PeriodicHeal:
            return Periodic(eventInfo) && Healed(eventInfo);
        case ProcEvent::CriticalDamage:
            return Landed(eventInfo) && Critical(eventInfo) && Dealt(eventInfo);
        case ProcEvent::CriticalHeal:
            return Landed(eventInfo) && Critical(eventInfo) && Healed(eventInfo);
        case ProcEvent::Critical:
            return Landed(eventInfo) && Critical(eventInfo) && (Dealt(eventInfo) || Healed(eventInfo));
        default:
            return false;
    }
}

class spell_ascension_mystic_enchant_proc : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_enchant_proc);

    std::array<TimePoint, MAX_SPELL_EFFECTS> _ready{};
    std::array<EffectRule const*, MAX_SPELL_EFFECTS> _fired{};

    bool CheckEffect(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        auto const itr = Rules.find(GetId());
        if (itr == Rules.end())
            return false;
        std::vector<EffectRule const*> const& rules = itr->second[effect->GetEffIndex()];
        auto const match = std::find_if(rules.begin(), rules.end(),
            [this, &eventInfo](EffectRule const* rule) { return Matches(*rule, GetTarget(), eventInfo); });
        if (match == rules.end())
            return false;
        EffectRule const* rule = *match;
        TimePoint const now = GameTime::Now();
        if (now < _ready[effect->GetEffIndex()])
            return false;
        float chance = rule->Chance;
        if (rule->ChancePerCombo > 0.0f && !rule->TargetAura.empty())
        {
            Unit const* target = Sides(GetTarget(), eventInfo).second;
            int32 stacks = 0;
            for (uint32 aura : rule->TargetAura)
                stacks = std::max(stacks, Stacks(target, aura, GetTarget()->GetGUID()));
            chance = rule->ChancePerCombo * float(stacks);
        }
        else if (rule->ChancePerCombo > 0.0f)
        {
            Player const* player = GetTarget()->ToPlayer();
            chance = player ? rule->ChancePerCombo * float(player->GetComboPoints()) : 0.0f;
        }
        if (chance < 100.0f && !roll_chance_f(chance))
            return false;
        _fired[effect->GetEffIndex()] = rule;
        return true;
    }

    void AimCastTrigger(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        EffectRule const* rule = _fired[effect->GetEffIndex()];
        bool const ruleTrigger = rule && !rule->TriggerSpells.empty();
        if (!ruleTrigger && (eventInfo.GetActionTarget() || HasActionScript()))
            return;
        SpellInfo const* trigger = sSpellMgr->GetSpellInfo(ruleTrigger ?
            Acore::Containers::SelectRandomContainerElement(rule->TriggerSpells) :
            effect->GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell);
        if (!trigger)
            return;
        Unit* caster = GetTarget();
        Spell const* spell = eventInfo.GetProcSpell();
        Unit* target = eventInfo.GetActionTarget() != caster ? eventInfo.GetActionTarget() : nullptr;
        if (!target && spell)
            target = spell->m_targets.GetUnitTarget();
        if (!target || (trigger->IsPositive() && !caster->IsFriendlyTo(target) && !TargetsEnemy(trigger)))
            target = caster;
        PreventDefaultAction();
        if (target != caster && trigger->Effects[EFFECT_0].TargetA.GetReferenceType() == TARGET_REFERENCE_TYPE_DEST)
            caster->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(), trigger->Id, true,
                nullptr, effect);
        else
            caster->CastSpell(target, trigger, true, nullptr, effect);
    }

    void CastPctTrigger(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SpellInfo const* trigger = sSpellMgr->GetSpellInfo(effect->GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell);
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        HealInfo const* heal = eventInfo.GetHealInfo();
        uint32 const amount = damage && damage->GetDamage() ? damage->GetDamage() : heal ? heal->GetHeal() : 0;
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (!trigger || !amount || !target)
            return;
        int32 basePoints = std::max(1, int32(CalculatePct(amount, effect->GetAmount())));
        caster->CastCustomSpell(target, trigger->Id, &basePoints, nullptr, nullptr, true, nullptr, effect);
    }

    bool CheckDummy(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        auto const itr = Rules.find(GetId());
        if (itr == Rules.end() || itr->second[effect->GetEffIndex()].empty())
            return true;
        return CheckEffect(effect, eventInfo);
    }

    void CastRuleTrigger(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        EffectRule const* rule = _fired[effect->GetEffIndex()];
        if (!rule)
            return;
        PreventDefaultAction();
        uint32 const triggerId = !rule->TriggerSpells.empty() ? Acore::Containers::SelectRandomContainerElement(rule->TriggerSpells) :
            effect->GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell;
        SpellInfo const* trigger = sSpellMgr->GetSpellInfo(triggerId);
        if (!trigger)
            return;
        Unit* caster = GetTarget();
        Spell const* spell = eventInfo.GetProcSpell();
        Unit* target = spell ? spell->m_targets.GetUnitTarget() : nullptr;
        if (!target)
            target = eventInfo.GetActionTarget() != caster ? eventInfo.GetActionTarget() : nullptr;
        if (!target || (trigger->IsPositive() && !caster->IsFriendlyTo(target) && !TargetsEnemy(trigger)))
            target = caster;
        if (rule->AmountPct <= 0.0f)
        {
            caster->CastSpell(target, trigger, true, nullptr, effect);
            return;
        }
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        HealInfo const* heal = eventInfo.GetHealInfo();
        uint32 const amount = damage && damage->GetDamage() ? damage->GetDamage() : heal ? heal->GetHeal() : 0;
        if (!amount)
            return;
        uint32 ticks = 1;
        for (SpellEffectInfo const& triggered : trigger->Effects)
            if (triggered.Amplitude && trigger->GetMaxDuration() > 0 &&
                (triggered.IsAura(SPELL_AURA_PERIODIC_DAMAGE) || triggered.IsAura(SPELL_AURA_PERIODIC_HEAL)))
                ticks = std::max<uint32>(1, uint32(trigger->GetMaxDuration()) / triggered.Amplitude);
        int32 basePoints = std::max(1, int32(float(amount) * rule->AmountPct / 100.0f / float(ticks)));
        caster->CastCustomSpell(target, trigger->Id, &basePoints, nullptr, nullptr, true, nullptr, effect);
    }

    bool HasActionScript() const
    {
        SpellScriptsBounds const bounds = sObjectMgr->GetSpellScriptsBounds(GetId());
        return std::distance(bounds.first, bounds.second) > 1;
    }

    void Consume(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        EffectRule const* rule = _fired[effect->GetEffIndex()];
        _fired[effect->GetEffIndex()] = nullptr;
        if (!rule)
            return;
        _ready[effect->GetEffIndex()] = GameTime::Now() + rule->Cooldown;
        Unit* target = eventInfo.GetActionTarget() != GetTarget() ? eventInfo.GetActionTarget() : nullptr;
        for (uint32 aura : rule->ConsumeAura)
        {
            GetTarget()->RemoveAurasDueToSpell(aura);
            if (target)
                target->RemoveAurasDueToSpell(aura, GetTarget()->GetGUID());
        }
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_mystic_enchant_proc::CheckEffect, EFFECT_ALL,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_enchant_proc::AimCastTrigger, EFFECT_ALL,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectProc += AuraEffectProcFn(spell_ascension_mystic_enchant_proc::Consume, EFFECT_ALL,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_mystic_enchant_proc::CheckDummy, EFFECT_ALL,
            SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_enchant_proc::CastRuleTrigger, EFFECT_ALL, SPELL_AURA_DUMMY);
        AfterEffectProc += AuraEffectProcFn(spell_ascension_mystic_enchant_proc::Consume, EFFECT_ALL, SPELL_AURA_DUMMY);
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_mystic_enchant_proc::CheckEffect, EFFECT_ALL,
            SPELL_AURA_ASCENSION_PROC_TRIGGER_PCT);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_enchant_proc::CastPctTrigger, EFFECT_ALL,
            SPELL_AURA_ASCENSION_PROC_TRIGGER_PCT);
        AfterEffectProc += AuraEffectProcFn(spell_ascension_mystic_enchant_proc::Consume, EFFECT_ALL,
            SPELL_AURA_ASCENSION_PROC_TRIGGER_PCT);
    }
};

class AscensionMysticEnchantProcsUnit final : public UnitScript
{
public:
    AscensionMysticEnchantProcsUnit() : UnitScript("AscensionMysticEnchantProcsUnit", true,
        { UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
          UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_MELEE_DAMAGE }) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit->IsPlayer() && HasMinionAura(aura->GetId()))
            SyncMinionAuras(unit);
        if (unit->IsPlayer())
            for (auto const& [watched, links] : Links)
                for (AuraLink const& link : links)
                    if (link.Enchant == aura->GetId() && watched != aura->GetId() && unit->HasAura(watched) &&
                        !unit->HasAura(link.Grant))
                        unit->CastSpell(unit, link.Grant, true);
        auto const itr = Links.find(aura->GetId());
        if (itr == Links.end() || !unit->IsPlayer())
            return;
        for (AuraLink const& link : itr->second)
            if (unit->HasAura(link.Enchant) && !unit->HasAura(link.Grant))
                unit->CastSpell(unit, link.Grant, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (unit->IsPlayer() && HasMinionAura(application->GetBase()->GetId()))
            SyncMinionAuras(unit);
        if (unit->IsPlayer())
            for (auto const& [watched, links] : Links)
                for (AuraLink const& link : links)
                    if (link.Enchant == application->GetBase()->GetId())
                        unit->RemoveAurasDueToSpell(link.Grant);
        auto const itr = Links.find(application->GetBase()->GetId());
        if (itr == Links.end() || !unit->IsPlayer())
            return;
        for (AuraLink const& link : itr->second)
            unit->RemoveAurasDueToSpell(link.Grant);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32&, SpellInfo const* spellInfo) override
    {
        Record(target, attacker, spellInfo);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32&, SpellInfo const* spellInfo) override
    {
        Record(target, attacker, spellInfo);
    }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32&) override
    {
        Record(target, attacker, nullptr);
    }

private:
    static void Record(Unit* target, Unit* attacker, SpellInfo const* spellInfo)
    {
        if (!target || !attacker || !attacker->IsPlayer() || target->IsPlayer())
            return;
        std::lock_guard<std::mutex> lock(LastHitsLock);
        LastHit& hit = LastHits[target->GetGUID()];
        hit.Attacker = attacker->GetGUID();
        hit.Spell = spellInfo ? spellInfo->Id : 0;
        hit.SchoolMask = spellInfo ? spellInfo->GetSchoolMask() : SPELL_SCHOOL_MASK_NORMAL;
        if (LastHits.size() > 20000)
            LastHits.clear();
    }
};

std::vector<uint32> Ids(std::string const& text)
{
    std::vector<uint32> ids;
    for (std::string_view token : Acore::Tokenize(text, ' ', false))
        if (Optional<uint32> id = Acore::StringTo<uint32>(token))
            ids.push_back(*id);
    return ids;
}

class AscensionMysticEnchantProcsWorld final : public WorldScript
{
public:
    AscensionMysticEnchantProcsWorld() : WorldScript("AscensionMysticEnchantProcsWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        LoadRules();
        LoadLinks();
    }

private:
    static void LoadRules()
    {
        Rules.clear();
        Storage.clear();
        QueryResult result = WorldDatabase.Query("SELECT enchant_spell, effect, event, school_mask, spells, chance, "
            "cooldown_ms, requires_aura, target_aura, conditions, consume_aura, trigger_spells, amount_pct, chance_per_combo "
            "FROM coa_mystic_enchant_proc");
        if (!result)
        {
            LOG_INFO("server.loading", ">> Loaded 0 Mystic Enchant proc rules");
            return;
        }
        Storage.reserve(result->GetRowCount());
        std::vector<std::pair<uint32, uint8>> keys;
        do
        {
            Field* fields = result->Fetch();
            uint32 const spell = fields[0].Get<uint32>();
            uint8 const effect = fields[1].Get<uint8>();
            std::string const eventName = fields[2].Get<std::string>();
            auto const event = EVENTS.find(eventName);
            if (effect >= MAX_SPELL_EFFECTS || event == EVENTS.end())
            {
                LOG_ERROR("sql.sql", "coa_mystic_enchant_proc: spell {} effect {} has an unknown event or effect",
                    spell, effect);
                continue;
            }
            EffectRule rule;
            rule.Event = event->second;
            rule.SchoolMask = fields[3].Get<uint32>();
            for (uint32 id : Ids(fields[4].Get<std::string>()))
                rule.Spells.insert(id);
            rule.Chance = fields[5].Get<float>();
            rule.Cooldown = Milliseconds(fields[6].Get<uint32>());
            rule.RequiresAura = Ids(fields[7].Get<std::string>());
            rule.TargetAura = Ids(fields[8].Get<std::string>());
            std::string const conditions = fields[9].Get<std::string>();
            bool valid = true;
            for (std::string_view token : Acore::Tokenize(conditions, ' ', false))
            {
                if (Optional<Condition> condition = ParseCondition(token))
                    rule.Conditions.push_back(*condition);
                else
                    valid = false;
            }
            if (!valid)
            {
                LOG_ERROR("sql.sql", "coa_mystic_enchant_proc: spell {} effect {} has an unknown condition '{}'",
                    spell, effect, conditions);
                continue;
            }
            rule.ConsumeAura = Ids(fields[10].Get<std::string>());
            rule.TriggerSpells = Ids(fields[11].Get<std::string>());
            rule.AmountPct = fields[12].Get<float>();
            rule.ChancePerCombo = fields[13].Get<float>();
            Storage.push_back(std::move(rule));
            keys.emplace_back(spell, effect);
        } while (result->NextRow());
        for (std::size_t index = 0; index < Storage.size(); ++index)
            Rules[keys[index].first][keys[index].second].push_back(&Storage[index]);
        LOG_INFO("server.loading", ">> Loaded {} Mystic Enchant proc rules for {} enchants", Storage.size(), Rules.size());
    }

    static void LoadLinks()
    {
        Links.clear();
        QueryResult result = WorldDatabase.Query("SELECT enchant_spell, aura, grant_spell FROM coa_mystic_enchant_aura_link");
        uint32 count = 0;
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                uint32 const grant = fields[2].Get<uint32>();
                if (!sSpellMgr->GetSpellInfo(grant))
                {
                    LOG_ERROR("sql.sql", "coa_mystic_enchant_aura_link: grant spell {} does not exist", grant);
                    continue;
                }
                for (uint32 aura : Ids(fields[1].Get<std::string>()))
                    Links[aura].push_back({ fields[0].Get<uint32>(), grant });
                ++count;
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} Mystic Enchant aura links", count);

        MinionAuras.clear();
        if (QueryResult minions = WorldDatabase.Query("SELECT enchant_spell, minion_entry, aura FROM coa_mystic_enchant_minion_aura"))
            do
            {
                Field* fields = minions->Fetch();
                MinionAura listener{ fields[0].Get<uint32>(), fields[1].Get<uint32>(), fields[2].Get<uint32>() };
                if (!sSpellMgr->GetSpellInfo(listener.Aura))
                {
                    LOG_ERROR("sql.sql", "coa_mystic_enchant_minion_aura: aura {} does not exist", listener.Aura);
                    continue;
                }
                MinionAuras.push_back(listener);
            } while (minions->NextRow());
        LOG_INFO("server.loading", ">> Loaded {} Mystic Enchant minion auras", MinionAuras.size());
    }
};

class AscensionMysticEnchantPets final : public PetScript
{
public:
    AscensionMysticEnchantPets() : PetScript("AscensionMysticEnchantPets", { PETHOOK_ON_PET_ADD_TO_WORLD }) { }

    void OnPetAddToWorld(Pet* pet) override
    {
        if (MinionAuras.empty() || !pet->GetOwner())
            return;
        ObjectGuid const ownerGuid = pet->GetOwner()->GetGUID();
        pet->m_Events.AddEventAtOffset([pet, ownerGuid]()
        {
            if (Player* owner = ObjectAccessor::FindPlayer(ownerGuid); owner && pet->IsInWorld())
                SyncMinionAuras(owner, pet);
        }, 500ms);
    }
};

class AscensionMysticEnchantMinions final : public AllCreatureScript
{
public:
    AscensionMysticEnchantMinions() : AllCreatureScript("AscensionMysticEnchantMinions") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (MinionAuras.empty() || !creature->IsSummon())
            return;
        Unit* owner = creature->GetOwner();
        if (owner && owner->IsPlayer())
            SyncMinionAuras(owner, creature);
    }
};
}

void AddSC_AscensionMysticEnchantProcs()
{
    RegisterSpellScript(spell_ascension_mystic_enchant_proc);
    new AscensionMysticEnchantProcsUnit();
    new AscensionMysticEnchantProcsWorld();
    new AscensionMysticEnchantMinions();
    new AscensionMysticEnchantPets();
}
