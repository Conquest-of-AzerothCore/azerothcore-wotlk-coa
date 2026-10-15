/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTinkerCombatSymbiosis.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <limits>

namespace
{
constexpr uint32 SPELL_COMBAT_SYMBIOSIS = 805305;
constexpr uint32 SPELL_COMBAT_SYMBIOSIS_HEAL = 807170;
constexpr AuraType COMBAT_SYMBIOSIS_AURA_TYPE = AuraType(354);

bool IsCombatSymbiosisAura(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_COMBAT_SYMBIOSIS ||
        spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6 || spellInfo->SpellFamilyFlags)
        return false;

    for (SpellEffIndex index : {EFFECT_0, EFFECT_1, EFFECT_2})
    {
        SpellEffectInfo const& effect = spellInfo->Effects[index];
        if (effect.Effect != SPELL_EFFECT_APPLY_AURA || effect.DieSides != 1 || effect.RealPointsPerLevel ||
            effect.TargetA.GetTarget() != TARGET_UNIT_TARGET_ALLY || effect.TargetB.GetTarget())
            return false;
    }

    return spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_HASTE_SPELLS &&
        spellInfo->Effects[EFFECT_0].BasePoints == 19 && !spellInfo->Effects[EFFECT_0].TriggerSpell &&
        spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_MELEE_RANGED_HASTE &&
        spellInfo->Effects[EFFECT_1].BasePoints == 19 && !spellInfo->Effects[EFFECT_1].TriggerSpell &&
        spellInfo->Effects[EFFECT_2].ApplyAuraName == COMBAT_SYMBIOSIS_AURA_TYPE &&
        spellInfo->Effects[EFFECT_2].BasePoints == 14 &&
        spellInfo->Effects[EFFECT_2].TriggerSpell == SPELL_COMBAT_SYMBIOSIS_HEAL;
}

void NormalizeCombatSymbiosisCharges(SpellInfo* spellInfo)
{
    if (IsCombatSymbiosisAura(spellInfo) && !spellInfo->ProcCharges)
        spellInfo->ProcCharges = 20;
}

class AscensionTinkerCombatSymbiosisMetadata : public GlobalScript
{
public:
    AscensionTinkerCombatSymbiosisMetadata()
        : GlobalScript("AscensionTinkerCombatSymbiosisMetadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        NormalizeCombatSymbiosisCharges(spellInfo);
    }
};

class aura_ascension_tinker_combat_symbiosis : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_combat_symbiosis);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_COMBAT_SYMBIOSIS_HEAL);
        if (!IsCombatSymbiosisAura(spellInfo) || spellInfo->ProcCharges != 20 || !helper ||
            helper->SpellFamilyName != uint32(CLASS_TINKER) + 6 || helper->SpellFamilyFlags ||
            helper->MaxAffectedTargets != 25 || !helper->HasAttribute(SPELL_ATTR2_CANT_CRIT) ||
            !helper->HasAttribute(SPELL_ATTR3_IGNORE_CASTER_MODIFIERS))
            return false;

        SpellEffectInfo const& effect = helper->Effects[EFFECT_0];
        return effect.Effect == SPELL_EFFECT_HEAL && effect.BasePoints == 0 && effect.DieSides == 1 &&
            !effect.RealPointsPerLevel && !effect.BonusMultiplier && effect.RadiusEntry &&
            effect.RadiusEntry->RadiusMin == 8.0f && effect.RadiusEntry->RadiusMax == 8.0f && !effect.RadiusEntry->RadiusPerLevel &&
            effect.TargetA.GetTarget() == TARGET_SRC_CASTER && effect.TargetB.GetTarget() == TARGET_UNIT_SRC_AREA_ALLY &&
            !helper->Effects[EFFECT_1].Effect && !helper->Effects[EFFECT_2].Effect;
    }

    bool Load() override
    {
        if (!GetUnitOwner() || !GetCasterGUID().IsPlayer())
            return false;

        Unit* caster = GetCaster();
        Player* player = caster ? caster->ToPlayer() : nullptr;
        return !caster || (player && player->getClass() == CLASS_TINKER);
    }

    bool CheckDamage(ProcEventInfo& eventInfo)
    {
        Unit* recipient = GetTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!recipient || eventInfo.GetActor() != recipient || !damage || damage->GetAttacker() != recipient ||
            !damage->GetDamage() || !damage->GetVictim() || damage->GetVictim() == recipient ||
            eventInfo.GetActionTarget() != damage->GetVictim() || recipient->IsFriendlyTo(damage->GetVictim()) ||
            GetAura()->IsExpired())
            return false;

        return damage->GetDamageType() == DIRECT_DAMAGE || damage->GetDamageType() == SPELL_DIRECT_DAMAGE ||
            damage->GetDamageType() == DOT;
    }

    void HealFromDamage(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!damage || effect->GetAmount() <= 0)
            return;

        uint64 amount = uint64(damage->GetDamage()) * uint32(effect->GetAmount()) / 100;
        if (!amount || double(float(amount)) > double(std::numeric_limits<int32>::max()))
            return;

        Unit* recipient = GetTarget();
        recipient->CastCustomSpell(SPELL_COMBAT_SYMBIOSIS_HEAL, SPELLVALUE_BASE_POINT0,
            int32(amount), recipient, true, nullptr, effect, recipient->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_combat_symbiosis::CheckDamage);
        OnEffectProc += AuraEffectProcFn(aura_ascension_tinker_combat_symbiosis::HealFromDamage, EFFECT_2, COMBAT_SYMBIOSIS_AURA_TYPE);
    }
};
}

void AddAscensionTinkerCombatSymbiosisScripts()
{
    new AscensionTinkerCombatSymbiosisMetadata();
    RegisterSpellScript(aura_ascension_tinker_combat_symbiosis);
}
