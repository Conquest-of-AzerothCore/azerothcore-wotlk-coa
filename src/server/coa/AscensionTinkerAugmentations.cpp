/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <array>
#include <cmath>
#include <limits>

namespace
{
constexpr uint32 AUGMENTATION_DURATION_MS = 60 * MINUTE * IN_MILLISECONDS;
constexpr uint32 SPELL_TRACER_MARK = 653247;
constexpr uint32 SPELL_TRACER_REVEAL = 653252;
constexpr uint32 SPELL_STIM_PASSIVE = 653240;
constexpr uint32 SPELL_STIM_HEAL = 653241;

struct Augmentation
{
    uint32 SpellId;
    uint32 EnchantmentId;
    uint32 PassiveId;
};

constexpr std::array<Augmentation, 6> AUGMENTATIONS =
{{
    {653130, 10000, 653232},
    {653234, 9999, 653235},
    {653236, 9998, 653237},
    {653239, 9997, 653240},
    {653242, 9996, 653243},
    {653245, 9995, 653246}
}};

Augmentation const* GetAugmentation(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6 ||
        spellInfo->SpellFamilyFlags != flag96(0, 0, 8388608) ||
        spellInfo->EquippedItemClass != ITEM_CLASS_WEAPON ||
        spellInfo->EquippedItemSubClassMask != (1 << ITEM_SUBCLASS_WEAPON_GUN) ||
        spellInfo->EquippedItemInventoryTypeMask)
        return nullptr;

    SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
    if (effect.Effect != SPELL_EFFECT_112 || effect.ApplyAuraName || effect.TriggerSpell ||
        effect.TargetA.GetTarget() || effect.TargetB.GetTarget() ||
        spellInfo->Effects[EFFECT_1].Effect || spellInfo->Effects[EFFECT_2].Effect)
        return nullptr;

    for (Augmentation const& augmentation : AUGMENTATIONS)
        if (augmentation.SpellId == spellInfo->Id && effect.MiscValue == int32(augmentation.EnchantmentId))
            return &augmentation;

    return nullptr;
}

Item* GetAugmentationGun(Player* player, SpellInfo const* spellInfo)
{
    if (!player || player->getClass() != CLASS_TINKER || !GetAugmentation(spellInfo))
        return nullptr;

    Item* gun = player->GetWeaponForAttack(RANGED_ATTACK);
    return gun && gun->GetOwner() == player && gun->IsFitToSpellRequirements(spellInfo) ? gun : nullptr;
}

class spell_ascension_tinker_augmentation : public SpellScript
{
    PrepareSpellScript(spell_ascension_tinker_augmentation);

    bool Validate(SpellInfo const* spellInfo) override
    {
        Augmentation const* augmentation = GetAugmentation(spellInfo);
        if (!augmentation || !ValidateSpellInfo({augmentation->PassiveId}))
            return false;

        SpellItemEnchantmentEntry const* enchantment =
            sSpellItemEnchantmentStore.LookupEntry(augmentation->EnchantmentId);
        return enchantment && enchantment->type[0] == ITEM_ENCHANTMENT_TYPE_EQUIP_SPELL &&
            enchantment->spellid[0] == augmentation->PassiveId &&
            !enchantment->type[1] && !enchantment->type[2] && !enchantment->charges &&
            !enchantment->EnchantmentCondition && !enchantment->requiredSkill && enchantment->requiredLevel == 1;
    }

    SpellCastResult CheckGun()
    {
        return GetAugmentationGun(GetCaster()->ToPlayer(), GetSpellInfo()) ?
            SPELL_CAST_OK : SPELL_FAILED_EQUIPPED_ITEM_CLASS;
    }

    void ApplyAugmentation(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetCaster()->ToPlayer();
        Item* gun = GetAugmentationGun(player, GetSpellInfo());
        Augmentation const* augmentation = GetAugmentation(GetSpellInfo());
        if (!gun || !augmentation)
            return;

        player->ApplyEnchantment(gun, TEMP_ENCHANTMENT_SLOT, false);
        gun->SetEnchantment(TEMP_ENCHANTMENT_SLOT, augmentation->EnchantmentId,
            AUGMENTATION_DURATION_MS, 0, player->GetGUID());
        player->ApplyEnchantment(gun, TEMP_ENCHANTMENT_SLOT, true);
        player->RemoveTradeableItem(gun);
        gun->ClearSoulboundTradeable(player);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_tinker_augmentation::CheckGun);
        OnEffectHit += SpellEffectFn(spell_ascension_tinker_augmentation::ApplyAugmentation,
            EFFECT_0, SPELL_EFFECT_112);
    }
};

float GetAugmentationRangedCoefficient(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6 ||
        spellInfo->Effects[EFFECT_0].Effect != SPELL_EFFECT_SCHOOL_DAMAGE ||
        spellInfo->Effects[EFFECT_0].BonusMultiplier != 0.0f ||
        spellInfo->Effects[EFFECT_1].Effect || spellInfo->Effects[EFFECT_2].Effect)
        return 0.0f;

    switch (spellInfo->Id)
    {
        case 653268:
            return 0.11f;
        case 653276:
            return 0.045f;
        case 653238:
            return 0.1f;
        default:
            return 0.0f;
    }
}

bool UsesAugmentationBaseScaling(SpellInfo const* spellInfo)
{
    return spellInfo && spellInfo->SpellFamilyName == uint32(CLASS_TINKER) + 6 &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
        spellInfo->Effects[EFFECT_0].BonusMultiplier == 0.0f &&
        spellInfo->Effects[EFFECT_0].DieSides == 1 && spellInfo->Effects[EFFECT_0].RealPointsPerLevel == 0.0f &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect &&
        (spellInfo->Id == 653268 || spellInfo->Id == 653238 || spellInfo->Id == 653274);
}

double AugmentationBaseMultiplier(uint8 level)
{
    return 0.0267291844060354 + 0.0048541098014737 * level + 0.0001859597762293 * level * level;
}

class spell_ascension_tinker_augmentation_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_tinker_augmentation_damage);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return GetAugmentationRangedCoefficient(spellInfo) > 0.0f || UsesAugmentationBaseScaling(spellInfo);
    }

    void ScaleBase()
    {
        Unit* caster = GetOriginalCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_TINKER || !GetSpell()->IsTriggered() ||
            !UsesAugmentationBaseScaling(GetSpellInfo()))
            return;

        SpellEffectInfo const& effect = GetSpellInfo()->Effects[EFFECT_0];
        if (GetSpell()->GetSpellValue()->EffectBasePoints[EFFECT_0] != effect.BasePoints)
            return;

        double value = (double(effect.BasePoints) + 1.0) * AugmentationBaseMultiplier(player->GetLevel());
        if (value >= std::numeric_limits<int32>::min() && value <= std::numeric_limits<int32>::max())
            GetSpell()->SetSpellValue(SPELLVALUE_BASE_POINT0, int32(value));
    }

    void AddRangedPower(SpellEffIndex)
    {
        Unit* caster = GetOriginalCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        Unit* target = GetHitUnit();
        float coefficient = GetAugmentationRangedCoefficient(GetSpellInfo());
        SpellBonusEntry const* bonus = sSpellMgr->GetSpellBonusData(GetSpellInfo()->Id);
        if (!player || player->getClass() != CLASS_TINKER || !target || !GetSpell()->IsTriggered() ||
            (coefficient <= 0.0f && !UsesAugmentationBaseScaling(GetSpellInfo())) ||
            !bonus || bonus->ap_bonus != 0.0f)
            return;

        float attackPower = player->GetTotalAttackPowerValue(RANGED_ATTACK) +
            target->GetTotalAuraModifier(SPELL_AURA_RANGED_ATTACK_POWER_ATTACKER_BONUS);
        double amount = double(coefficient * attackPower);
        if (!std::isfinite(amount) || amount < std::numeric_limits<int32>::min() ||
            amount > std::numeric_limits<int32>::max())
            return;

        int64 value = int64(GetEffectValue()) + int32(amount);
        if (value >= std::numeric_limits<int32>::min() && value <= std::numeric_limits<int32>::max())
            SetEffectValue(int32(value));
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_tinker_augmentation_damage::ScaleBase);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_tinker_augmentation_damage::AddRangedPower,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

bool IsTracerMark(SpellInfo const* spellInfo)
{
    return spellInfo && spellInfo->Id == SPELL_TRACER_MARK &&
        spellInfo->SpellFamilyName == uint32(CLASS_TINKER) + 6 && spellInfo->StackAmount == 5 &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA &&
        spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY &&
        spellInfo->Effects[EFFECT_2].Effect == SPELL_EFFECT_APPLY_AURA &&
        spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE &&
        spellInfo->Effects[EFFECT_2].DieSides == 1 &&
        spellInfo->Effects[EFFECT_2].RealPointsPerLevel == 0.0f &&
        spellInfo->Effects[EFFECT_2].BonusMultiplier == 0.0f;
}

class spell_ascension_tinker_tracer : public SpellScript
{
    PrepareSpellScript(spell_ascension_tinker_tracer);

    int32 _remaining = 0;
    int32 _periodicTimer = 0;

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTracerMark(spellInfo);
    }

    void PrepareDamage()
    {
        Unit* caster = GetOriginalCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        Unit* target = GetExplTargetUnit();
        SpellInfo const* spellInfo = GetSpellInfo();
        SpellBonusEntry const* bonus = sSpellMgr->GetSpellBonusData(spellInfo->Id);
        if (!player || player->getClass() != CLASS_TINKER || !target || !GetSpell()->IsTriggered() ||
            !IsTracerMark(spellInfo) || !bonus || bonus->ap_dot_bonus != 0.0f)
            return;

        SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_2];
        if (GetSpell()->GetSpellValue()->EffectBasePoints[EFFECT_2] != effect.BasePoints)
            return;

        float attackPower = player->GetTotalAttackPowerValue(RANGED_ATTACK) +
            target->GetTotalAuraModifier(SPELL_AURA_RANGED_ATTACK_POWER_ATTACKER_BONUS);
        double value = (double(effect.BasePoints) + 1.0) * AugmentationBaseMultiplier(player->GetLevel()) +
            double(0.08f * attackPower);
        if (std::isfinite(value) && value >= std::numeric_limits<int32>::min() &&
            value <= std::numeric_limits<int32>::max())
            GetSpell()->SetSpellValue(SPELLVALUE_BASE_POINT2, int32(value));
    }

    void CaptureTimer(SpellMissInfo)
    {
        _remaining = 0;
        Unit* caster = GetOriginalCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;

        if (Aura* aura = target->GetAura(SPELL_TRACER_MARK, caster->GetGUID()))
            if (AuraEffect* effect = aura->GetEffect(EFFECT_2))
            {
                _remaining = aura->GetDuration();
                _periodicTimer = effect->GetPeriodicTimer();
            }
    }

    void RestoreTimer()
    {
        if (_remaining <= 0)
            return;

        if (Aura* aura = GetHitAura())
            if (IsTracerMark(aura->GetSpellInfo()))
            {
                aura->SetDuration(_remaining);
                if (AuraEffect* effect = aura->GetEffect(EFFECT_2))
                    effect->SetPeriodicTimer(_periodicTimer);
            }
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_tinker_tracer::PrepareDamage);
        BeforeHit += BeforeSpellHitFn(spell_ascension_tinker_tracer::CaptureTimer);
        AfterHit += SpellHitFn(spell_ascension_tinker_tracer::RestoreTimer);
    }
};

class aura_ascension_tinker_tracer : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_tracer);

    bool _exploded = false;

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTracerMark(spellInfo) && ValidateSpellInfo({SPELL_TRACER_REVEAL});
    }

    void Reveal(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Unit* caster = GetCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (player && player->getClass() == CLASS_TINKER)
            caster->CastSpell(GetTarget(), SPELL_TRACER_REVEAL, true, nullptr, effect);
    }

    void ExplodeAtExpiry(AuraEffect const*, bool& isPeriodic, int32& amplitude)
    {
        int32 const extension = GetMaxDuration() - GetSpellInfo()->GetMaxDuration();
        if (isPeriodic && extension > 0)
            amplitude += extension;
    }

    void OneExplosion(AuraEffect const*)
    {
        if (_exploded)
            PreventDefaultAction();
        _exploded = true;
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_tinker_tracer::Reveal,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_tinker_tracer::ExplodeAtExpiry,
            EFFECT_2, SPELL_AURA_PERIODIC_DAMAGE);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_tinker_tracer::OneExplosion,
            EFFECT_2, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

bool IsStimPassive(SpellInfo const* spellInfo)
{
    return spellInfo && spellInfo->Id == SPELL_STIM_PASSIVE &&
        spellInfo->SpellFamilyName == uint32(CLASS_TINKER) + 6 &&
        spellInfo->SpellFamilyFlags == flag96(0, 0, 67108864) &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_APPLY_AURA &&
        spellInfo->Effects[EFFECT_0].ApplyAuraName == 354 &&
        spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_STIM_HEAL &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;
}

class aura_ascension_tinker_stim : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_stim);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsStimPassive(spellInfo) && ValidateSpellInfo({SPELL_STIM_HEAL});
    }

    bool CheckHeal(ProcEventInfo& eventInfo)
    {
        Player* player = GetTarget()->ToPlayer();
        HealInfo const* heal = eventInfo.GetHealInfo();
        SpellInfo const* spellInfo = heal ? heal->GetSpellInfo() : nullptr;
        return player && player->getClass() == CLASS_TINKER && eventInfo.GetActor() == player &&
            heal && heal->GetHealer() == player && heal->GetTarget() && heal->GetEffectiveHeal() &&
            spellInfo && spellInfo->Id != SPELL_STIM_HEAL &&
            !(eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void Heal(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (!CheckHeal(eventInfo) || effect->GetAmount() <= 0)
            return;

        HealInfo const* heal = eventInfo.GetHealInfo();
        double amount = double(heal->GetEffectiveHeal()) * effect->GetAmount() / 100.0;
        if (amount < 1.0 || amount > std::numeric_limits<int32>::max())
            return;

        GetTarget()->CastCustomSpell(SPELL_STIM_HEAL, SPELLVALUE_BASE_POINT0, int32(amount),
            heal->GetTarget(), true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_stim::CheckHeal);
        OnEffectProc += AuraEffectProcFn(aura_ascension_tinker_stim::Heal,
            EFFECT_0, static_cast<AuraType>(354));
    }
};

void NormalizeBandageGun(SpellInfo* spellInfo)
{
    if (!spellInfo || spellInfo->Id != 705780 || spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6)
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
    if (effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        effect.MiscValue == SPELLMOD_JUMP_TARGETS && effect.SpellClassMask == flag96(128, 0, 0) &&
        effect.BasePoints == 2 && effect.DieSides == 1 && !effect.RealPointsPerLevel)
        effect.BasePoints = 1;
}

class AscensionTinkerAugmentationMetadata : public GlobalScript
{
public:
    AscensionTinkerAugmentationMetadata()
        : GlobalScript("AscensionTinkerAugmentationMetadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        NormalizeBandageGun(spellInfo);
    }
};
}

void AddAscensionTinkerAugmentationScripts()
{
    RegisterSpellScript(spell_ascension_tinker_augmentation);
    RegisterSpellScript(spell_ascension_tinker_augmentation_damage);
    RegisterSpellScript(spell_ascension_tinker_tracer);
    RegisterSpellScript(aura_ascension_tinker_tracer);
    RegisterSpellScript(aura_ascension_tinker_stim);
    new AscensionTinkerAugmentationMetadata();
}
