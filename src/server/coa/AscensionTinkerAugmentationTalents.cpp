/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>
#include <array>
#include <limits>

namespace
{
constexpr uint32 SPELL_AUGMENTOR = 801821;
constexpr uint32 SPELL_AETHER_PASSIVE = 653232;
constexpr uint32 SPELL_PIERCING_PASSIVE = 653235;
constexpr uint32 SPELL_STIM_HEAL = 653241;
constexpr uint32 SPELL_STIM_PACK = 807531;
constexpr uint32 SPELL_STIM_COOLDOWN = 653255;
constexpr uint32 SPELL_CYBERNETIC_TALENT = 807748;
constexpr uint32 SPELL_CYBERNETIC_SHIELD = 653283;
constexpr std::array<uint32, 5> MED_PACK_RANKS = {800347, 502533, 502534, 502535, 502536};

bool IsTinkerSpell(SpellInfo const* spellInfo, uint32 id)
{
    return spellInfo && spellInfo->Id == id && spellInfo->SpellFamilyName == uint32(CLASS_TINKER) + 6;
}

void NormalizeAugmentor(SpellInfo* spellInfo)
{
    if (!IsTinkerSpell(spellInfo, SPELL_AUGMENTOR))
        return;

    SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
    if (effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_ADD_FLAT_MODIFIER &&
        effect.MiscValue == SPELLMOD_EFFECT3 && effect.SpellClassMask == flag96(9, 0, 0) &&
        effect.BasePoints == 9 && effect.DieSides == 1 && !effect.RealPointsPerLevel &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect)
        effect.ApplyAuraName = SPELL_AURA_MOD_RANGED_HASTE;
}

class AscensionTinkerAugmentationTalentMetadata : public GlobalScript
{
public:
    AscensionTinkerAugmentationTalentMetadata()
        : GlobalScript("AscensionTinkerAugmentationTalentMetadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        NormalizeAugmentor(spellInfo);
    }
};

class aura_ascension_tinker_augmentor : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_augmentor);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTinkerSpell(spellInfo, SPELL_AUGMENTOR) &&
            spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_MOD_RANGED_HASTE;
    }

    void CalculateHaste(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        Unit* owner = GetUnitOwner();
        Player* player = owner ? owner->ToPlayer() : nullptr;
        canBeRecalculated = true;
        if (!player || player->getClass() != CLASS_TINKER ||
            (!player->HasAura(SPELL_AETHER_PASSIVE) && !player->HasAura(SPELL_PIERCING_PASSIVE)))
            amount = 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_ascension_tinker_augmentor::CalculateHaste,
            EFFECT_0, SPELL_AURA_MOD_RANGED_HASTE);
    }
};

class AscensionTinkerAugmentorLifecycle : public UnitScript
{
    static void Refresh(Unit* unit, uint32 changedSpell)
    {
        if (changedSpell != SPELL_AETHER_PASSIVE && changedSpell != SPELL_PIERCING_PASSIVE)
            return;

        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (player && player->getClass() == CLASS_TINKER)
            if (AuraEffect* effect = player->GetAuraEffect(SPELL_AUGMENTOR, EFFECT_0))
                if (effect->GetAuraType() == SPELL_AURA_MOD_RANGED_HASTE)
                    effect->RecalculateAmount();
    }

public:
    AscensionTinkerAugmentorLifecycle()
        : UnitScript("AscensionTinkerAugmentorLifecycle", true, {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (aura)
            Refresh(unit, aura->GetId());
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (application)
            Refresh(unit, application->GetBase()->GetId());
    }
};

HealInfo const* EffectiveStimHeal(Unit* owner, ProcEventInfo& eventInfo)
{
    Player* player = owner ? owner->ToPlayer() : nullptr;
    HealInfo const* heal = eventInfo.GetHealInfo();
    if (!player || player->getClass() != CLASS_TINKER || eventInfo.GetActor() != player ||
        !heal || heal->GetHealer() != player || !heal->GetTarget() || !heal->GetEffectiveHeal() ||
        !IsTinkerSpell(heal->GetSpellInfo(), SPELL_STIM_HEAL) ||
        (eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC))
        return nullptr;

    return heal;
}

class aura_ascension_tinker_stim_pack : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_stim_pack);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTinkerSpell(spellInfo, SPELL_STIM_PACK) &&
            spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_STIM_COOLDOWN &&
            ValidateSpellInfo({SPELL_STIM_COOLDOWN});
    }

    bool CheckHeal(ProcEventInfo& eventInfo)
    {
        return EffectiveStimHeal(GetTarget(), eventInfo) != nullptr;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_stim_pack::CheckHeal);
    }
};

class spell_ascension_tinker_stim_cooldown : public SpellScript
{
    PrepareSpellScript(spell_ascension_tinker_stim_cooldown);

    bool Validate(SpellInfo const* spellInfo) override
    {
        if (!IsTinkerSpell(spellInfo, SPELL_STIM_COOLDOWN))
            return false;

        SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
        return effect.Effect == SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN && effect.MiscValue == 800347 &&
            !effect.MiscValueB && effect.BasePoints == -3001 && effect.DieSides == 1;
    }

    void ReduceCooldown(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* player = GetCaster()->ToPlayer();
        int32 delta = GetEffectValue();
        if (!player || player->getClass() != CLASS_TINKER || !GetSpell()->IsTriggered() || delta >= 0)
            return;

        for (uint32 id : MED_PACK_RANKS)
        {
            SpellInfo const* rank = sSpellMgr->GetSpellInfo(id);
            if (!IsTinkerSpell(rank, id) || rank->SpellFamilyFlags != flag96(0, 0, 32768) ||
                rank->GetCategory() != 725 || rank->MaxCharges)
                continue;

            uint32 remaining = player->GetSpellCooldownDelay(id);
            if (!remaining)
                continue;

            if (uint64(-int64(delta)) >= remaining)
                player->RemoveSpellCooldown(id, true);
            else
                player->ModifySpellCooldown(id, delta);
        }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_tinker_stim_cooldown::ReduceCooldown,
            EFFECT_0, SPELL_EFFECT_ASCENSION_MODIFY_COOLDOWN);
    }
};

class aura_ascension_tinker_cybernetic : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_cybernetic);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTinkerSpell(spellInfo, SPELL_CYBERNETIC_TALENT) &&
            spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY &&
            spellInfo->Effects[EFFECT_0].MiscValueB == 10 && ValidateSpellInfo({SPELL_CYBERNETIC_SHIELD});
    }

    bool CheckHeal(ProcEventInfo& eventInfo)
    {
        return EffectiveStimHeal(GetTarget(), eventInfo) != nullptr;
    }

    void Shield(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        HealInfo const* heal = EffectiveStimHeal(GetTarget(), eventInfo);
        if (!heal || effect->GetAmount() <= 0)
            return;

        uint64 amount = uint64(heal->GetEffectiveHeal()) * uint32(effect->GetAmount()) / 100;
        if (!amount || amount > uint64(std::numeric_limits<int32>::max()) ||
            heal->GetTarget()->GetMaxHealth() < 10)
            return;

        GetTarget()->CastCustomSpell(SPELL_CYBERNETIC_SHIELD, SPELLVALUE_BASE_POINT0, int32(amount),
            heal->GetTarget(), true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_cybernetic::CheckHeal);
        OnEffectProc += AuraEffectProcFn(aura_ascension_tinker_cybernetic::Shield, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_ascension_tinker_cybernetic_shield : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_cybernetic_shield);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTinkerSpell(spellInfo, SPELL_CYBERNETIC_SHIELD) &&
            spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_SCHOOL_ABSORB &&
            spellInfo->Effects[EFFECT_0].MiscValue == 127;
    }

    void LimitCapacity(AuraEffect const*, AuraEffectHandleModes)
    {
        if (AuraEffect* effect = GetEffect(EFFECT_0))
        {
            int32 limit = int32(std::min<uint64>(uint64(GetTarget()->GetMaxHealth()) / 10,
                uint64(std::numeric_limits<int32>::max())));
            effect->ChangeAmount(std::clamp(effect->GetAmount(), 0, limit));
        }
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_tinker_cybernetic_shield::LimitCapacity,
            EFFECT_0, SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};
}

void AddAscensionTinkerAugmentationTalentScripts()
{
    new AscensionTinkerAugmentationTalentMetadata();
    new AscensionTinkerAugmentorLifecycle();
    RegisterSpellScript(aura_ascension_tinker_augmentor);
    RegisterSpellScript(aura_ascension_tinker_stim_pack);
    RegisterSpellScript(spell_ascension_tinker_stim_cooldown);
    RegisterSpellScript(aura_ascension_tinker_cybernetic);
    RegisterSpellScript(aura_ascension_tinker_cybernetic_shield);
}
