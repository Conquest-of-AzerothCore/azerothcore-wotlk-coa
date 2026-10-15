/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>
#include <limits>
#include <vector>

namespace
{
enum CremationSpells : uint32
{
    Fireball = 133,
    Pyroblast = 11366,
    LivingBomb = 44457,
    SearingBrandFirst = 289443,
    SearingBrandLast = 289455,
    CremationBurn = 278068
};

bool IsConsumedSpell(SpellInfo const* info)
{
    if (info->Id >= SearingBrandFirst && info->Id <= SearingBrandLast)
        return true;
    if (info->SpellFamilyName != SPELLFAMILY_MAGE)
        return false;
    uint32 const first = sSpellMgr->GetFirstSpellInChain(info->Id);
    return first == Fireball || first == Pyroblast || first == LivingBomb;
}

class spell_ascension_wildcard_cremation : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_cremation);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({CremationBurn}) &&
            sSpellMgr->GetSpellInfo(CremationBurn)->Effects[EFFECT_0].IsAura(SPELL_AURA_PERIODIC_DAMAGE) &&
            sSpellMgr->GetSpellInfo(CremationBurn)->Effects[EFFECT_0].Amplitude > 0 &&
            sSpellMgr->GetSpellInfo(CremationBurn)->GetDuration() > 0;
    }

    SpellCastResult CheckCast()
    {
        if (Unit* target = GetExplTargetUnit())
            for (AuraEffect const* effect : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_DAMAGE))
                if (effect->GetCasterGUID() == GetCaster()->GetGUID() && IsConsumedSpell(effect->GetSpellInfo()))
                    return SPELL_CAST_OK;
        return SPELL_FAILED_BAD_TARGETS;
    }

    void Consume(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        uint64 remainingDamage = 0;
        std::vector<uint32> consumed;
        for (AuraEffect const* effect : target->GetAuraEffectsByType(SPELL_AURA_PERIODIC_DAMAGE))
        {
            if (effect->GetCasterGUID() != GetCaster()->GetGUID() || !IsConsumedSpell(effect->GetSpellInfo()))
                continue;
            int32 const amplitude = effect->GetAmplitude();
            int32 const duration = effect->GetBase()->GetDuration();
            int32 const nextTick = std::max(0, effect->GetPeriodicTimer());
            uint32 const ticks = amplitude > 0 && duration >= nextTick ? 1 + (duration - nextTick) / amplitude : 0;
            remainingDamage = std::min(remainingDamage + uint64(std::max(0, effect->GetAmount())) * ticks,
                uint64(std::numeric_limits<int32>::max()) / 7);
            consumed.push_back(effect->GetId());
        }
        if (consumed.empty())
            return;
        for (uint32 spell : consumed)
            target->RemoveAurasDueToSpell(spell, GetCaster()->GetGUID());
        SpellInfo const* burn = sSpellMgr->GetSpellInfo(CremationBurn);
        int32 const ticks = burn->GetDuration() / burn->Effects[EFFECT_0].Amplitude;
        if (ticks <= 0)
            return;
        uint32 const level = GetCaster()->GetLevel();
        int32 amount = int32(std::min(remainingDamage * 7 + urand(level * 35, level * 37),
            uint64(std::numeric_limits<int32>::max())) / ticks);
        GetCaster()->CastCustomSpell(target, CremationBurn, &amount, nullptr, nullptr, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_wildcard_cremation::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_wildcard_cremation::Consume, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionWildcardCremation()
{
    RegisterSpellScript(spell_ascension_wildcard_cremation);
}
