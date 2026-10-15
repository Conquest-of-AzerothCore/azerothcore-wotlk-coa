/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>
#include <set>
#include <vector>

namespace
{
enum WildheartSpells : uint32
{
    Wildheart = 803980,
    WildheartRecovery = 810040
};

bool DealsDamage(SpellInfo const* info, std::set<uint32>& visited)
{
    if (!info || !visited.insert(info->Id).second)
        return false;
    for (SpellEffectInfo const& effect : info->Effects)
    {
        if (!effect.IsEffect())
            continue;
        switch (effect.Effect)
        {
            case SPELL_EFFECT_SCHOOL_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
            case SPELL_EFFECT_HEALTH_LEECH:
            case SPELL_EFFECT_POWER_BURN:
            case SPELL_EFFECT_INSTAKILL:
                return true;
            default:
                break;
        }
        switch (effect.ApplyAuraName)
        {
            case SPELL_AURA_PERIODIC_DAMAGE:
            case SPELL_AURA_PERIODIC_DAMAGE_PERCENT:
            case SPELL_AURA_PERIODIC_LEECH:
            case SPELL_AURA_POWER_BURN:
                return true;
            default:
                break;
        }
        if (effect.TriggerSpell && (effect.Effect == SPELL_EFFECT_TRIGGER_SPELL ||
            effect.Effect == SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE ||
            effect.Effect == SPELL_EFFECT_TRIGGER_MISSILE ||
            effect.Effect == SPELL_EFFECT_TRIGGER_MISSILE_SPELL_WITH_VALUE ||
            effect.Effect == SPELL_EFFECT_FORCE_CAST || effect.Effect == SPELL_EFFECT_FORCE_CAST_WITH_VALUE ||
            effect.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL ||
            effect.ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE))
            if (DealsDamage(sSpellMgr->GetSpellInfo(effect.TriggerSpell), visited))
                return true;
    }
    return false;
}

class aura_ascension_wildheart : public AuraScript
{
    PrepareAuraScript(aura_ascension_wildheart);

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    void Reduce(AuraEffect const* effect)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        std::vector<uint32> cooldowns;
        for (auto const& [id, cooldown] : player->GetSpellCooldownMap())
        {
            SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
            std::set<uint32> visited;
            if (id != Wildheart && info && player->GetSpellCooldownDelay(id) < infinityCooldownDelayCheck &&
                !DealsDamage(info, visited))
                cooldowns.push_back(id);
        }
        for (uint32 id : cooldowns)
        {
            uint32 reduction = uint32(uint64(player->GetSpellCooldownDelay(id)) *
                std::clamp(effect->GetAmount(), 0, 100) / 100);
            if (reduction)
                player->ModifySpellCooldown(id, -int32(std::min<uint32>(reduction,
                    std::numeric_limits<int32>::max())));
        }
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_wildheart::Reduce,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};

class primalist_wildheart_metadata : public GlobalScript
{
public:
    primalist_wildheart_metadata() : GlobalScript("primalist_wildheart_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != WildheartRecovery || info->SpellFamilyName != 37)
            return;
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.MiscValueB == 1)
            {
                if (effect.Effect == SPELL_EFFECT_HEAL_PCT)
                    effect.Effect = SPELL_EFFECT_HEAL;
                else if (effect.Effect == SPELL_EFFECT_ENERGIZE_PCT)
                    effect.Effect = SPELL_EFFECT_ENERGIZE;
            }
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
    }
};

class spell_ascension_wildheart_recovery : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildheart_recovery);

    void Amount(SpellEffIndex index)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        bool health = index == EFFECT_0;
        Powers power = index == EFFECT_1 ? POWER_MANA : POWER_RAGE;
        uint64 maximum = health ? target->GetMaxHealth() : target->GetMaxPower(power);
        uint64 current = health ? target->GetHealth() : target->GetPower(power);
        uint64 amount = (maximum - std::min(current, maximum)) * std::clamp(GetEffectValue(), 0, 100) / 100;
        SetEffectValue(int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_wildheart_recovery::Amount,
            EFFECT_0, SPELL_EFFECT_HEAL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_wildheart_recovery::Amount,
            EFFECT_1, SPELL_EFFECT_ENERGIZE);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_wildheart_recovery::Amount,
            EFFECT_2, SPELL_EFFECT_ENERGIZE);
    }
};
}

void AddSC_AscensionPrimalistWildheart()
{
    new primalist_wildheart_metadata();
    RegisterSpellScript(aura_ascension_wildheart);
    RegisterSpellScript(spell_ascension_wildheart_recovery);
}
