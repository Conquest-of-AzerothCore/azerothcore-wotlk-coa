/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// Warcraft Reborn Mystic Enchants whose proc event lived server-side on Ascension.
//
// Most custom enchants are a proc-trigger aura with ProcFlags 0 and no class mask: the only record of the event is
// the tooltip ("Casting Wrath restores 20 energy", "Dealing damage with Mongoose Bite applies Deadly Bite"), and an
// enchant can carry several proc effects with different events. spell_proc can only describe one event per aura
// and selects by family flags, which Reborn abilities share widely, so each enchant gets a broad spell_proc row and
// this script, which accepts an effect's proc only for its own event and abilities (coa_mystic_enchant_proc).

#include "DatabaseEnv.h"
#include "Field.h"
#include "GameTime.h"
#include "Log.h"
#include "Player.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "StringConvert.h"
#include "Tokenize.h"
#include "Unit.h"
#include "WorldScript.h"
#include <algorithm>
#include <array>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
enum class ProcEvent : uint8
{
    Cast,            // the spell is cast (cast phase)
    Hit,             // the spell lands, whatever it does
    Damage,          // the spell deals damage, direct or periodic
    DirectDamage,
    PeriodicDamage,
    Heal,            // the spell heals, direct or periodic
    DirectHeal,
    PeriodicHeal,
    CriticalDamage,
    CriticalHeal,
    Critical,        // a critical damage or heal
    Kill,            // the player kills a target that yields experience or honor (kill events carry no spell)
    Parry,           // the player parries a melee attack
    Dodged,          // the player's melee attack is dodged
    AutoAttack       // the player's melee auto attack lands
};

std::unordered_map<std::string_view, ProcEvent> const EVENTS = {
    {"cast", ProcEvent::Cast}, {"hit", ProcEvent::Hit}, {"damage", ProcEvent::Damage},
    {"direct_damage", ProcEvent::DirectDamage}, {"periodic_damage", ProcEvent::PeriodicDamage},
    {"heal", ProcEvent::Heal}, {"direct_heal", ProcEvent::DirectHeal}, {"periodic_heal", ProcEvent::PeriodicHeal},
    {"critical_damage", ProcEvent::CriticalDamage}, {"critical_heal", ProcEvent::CriticalHeal},
    {"critical", ProcEvent::Critical}, {"kill", ProcEvent::Kill}, {"parry", ProcEvent::Parry},
    {"dodged", ProcEvent::Dodged}, {"auto_attack", ProcEvent::AutoAttack}};

struct EffectRule
{
    ProcEvent Event = ProcEvent::Cast;
    uint32 SchoolMask = 0;                 // 0 = any school
    std::unordered_set<uint32> Spells;     // every rank; empty = any spell
    std::vector<uint32> RequiresAura;      // "while X is active": the player has one of these
    std::vector<uint32> TargetAura;        // "on targets affected by your X": the target has one of these from the player
    float Chance = 100.0f;                 // rolled per effect, on top of the aura's own proc chance
    Milliseconds Cooldown = 0ms;           // per effect, per aura
};

std::unordered_map<uint32, std::array<std::vector<EffectRule const*>, MAX_SPELL_EFFECTS>> Rules;
std::vector<EffectRule> Storage;

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

bool Conditions(EffectRule const& rule, ProcEventInfo& eventInfo)
{
    Unit* actor = eventInfo.GetActor();
    if (!rule.RequiresAura.empty() && !HasAny(actor, rule.RequiresAura))
        return false;
    return rule.TargetAura.empty() ||
        (actor && HasAny(eventInfo.GetActionTarget(), rule.TargetAura, actor->GetGUID()));
}

bool Matches(EffectRule const& rule, ProcEventInfo& eventInfo)
{
    if (!Conditions(rule, eventInfo))
        return false;
    if (rule.Event == ProcEvent::Kill)
    {
        if (!(eventInfo.GetTypeMask() & PROC_FLAG_KILL))
            return false;
        Player* player = eventInfo.GetActor() ? eventInfo.GetActor()->ToPlayer() : nullptr;
        return player && eventInfo.GetActionTarget() && player->isHonorOrXPTarget(eventInfo.GetActionTarget());
    }
    if (rule.Event == ProcEvent::Parry)
        return (eventInfo.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS)) &&
            (eventInfo.GetHitMask() & PROC_HIT_PARRY);
    if (rule.Event == ProcEvent::AutoAttack)
        return (eventInfo.GetTypeMask() & PROC_FLAG_DONE_MELEE_AUTO_ATTACK) &&
            (eventInfo.GetHitMask() & (PROC_HIT_NORMAL | PROC_HIT_CRITICAL));
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

    bool CheckEffect(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        auto const itr = Rules.find(GetId());
        if (itr == Rules.end())
            return false;
        // an effect without a matching rule never procs: it would otherwise fire on every event the broad spell_proc
        // row admits
        std::vector<EffectRule const*> const& rules = itr->second[effect->GetEffIndex()];
        auto const match = std::find_if(rules.begin(), rules.end(),
            [&eventInfo](EffectRule const* rule) { return Matches(*rule, eventInfo); });
        if (match == rules.end())
            return false;
        EffectRule const* rule = *match;
        TimePoint const now = GameTime::Now();
        if (now < _ready[effect->GetEffIndex()])
            return false;
        if (rule->Chance < 100.0f && !roll_chance_f(rule->Chance))
            return false;
        _ready[effect->GetEffIndex()] = now + rule->Cooldown;
        return true;
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_mystic_enchant_proc::CheckEffect, EFFECT_ALL,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class AscensionMysticEnchantProcsWorld final : public WorldScript
{
public:
    AscensionMysticEnchantProcsWorld() : WorldScript("AscensionMysticEnchantProcsWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        Rules.clear();
        Storage.clear();
        QueryResult result = WorldDatabase.Query("SELECT enchant_spell, effect, event, school_mask, spells, chance, "
            "cooldown_ms, requires_aura, target_aura FROM coa_mystic_enchant_proc");
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
            std::string const spells = fields[4].Get<std::string>();
            for (std::string_view token : Acore::Tokenize(spells, ' ', false))
                if (Optional<uint32> id = Acore::StringTo<uint32>(token))
                    rule.Spells.insert(*id);
            rule.Chance = fields[5].Get<float>();
            rule.Cooldown = Milliseconds(fields[6].Get<uint32>());
            for (uint8 column : { uint8(7), uint8(8) })
            {
                std::string const auras = fields[column].Get<std::string>();
                for (std::string_view token : Acore::Tokenize(auras, ' ', false))
                    if (Optional<uint32> id = Acore::StringTo<uint32>(token))
                        (column == 7 ? rule.RequiresAura : rule.TargetAura).push_back(*id);
            }
            Storage.push_back(std::move(rule));
            keys.emplace_back(spell, effect);
        } while (result->NextRow());
        for (std::size_t index = 0; index < Storage.size(); ++index)
            Rules[keys[index].first][keys[index].second].push_back(&Storage[index]);
        LOG_INFO("server.loading", ">> Loaded {} Mystic Enchant proc rules for {} enchants", Storage.size(), Rules.size());
    }
};
}

void AddSC_AscensionMysticEnchantProcs()
{
    RegisterSpellScript(spell_ascension_mystic_enchant_proc);
    new AscensionMysticEnchantProcsWorld();
}
