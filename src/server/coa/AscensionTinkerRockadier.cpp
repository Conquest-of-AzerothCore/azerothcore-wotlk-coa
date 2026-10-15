/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTinkerRockadier.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <array>
#include <limits>

namespace
{
constexpr uint32 SPELL_ROCKADIER = 801827;
constexpr uint32 SPELL_ROCKADIER_DAMAGE = 805979;
constexpr uint32 SPELL_ROCKET_BARRAGE = 805314;
constexpr uint32 SPELL_ROCKET_LAUNCHER_DAMAGE = 500220;
constexpr uint8 ROCKADIER_ATTACK_EVENT = 19;
constexpr AuraType ROCKADIER_AURA_TYPE = AuraType(354);
constexpr std::array<uint32, 7> SCRAP_SHOT_RANKS = {500549, 500556, 500557, 500558, 500559, 500560, 500561};

bool CanCopyRockadierDamage(uint32 damage)
{
    return damage && double(float(damage)) <= double(std::numeric_limits<int32>::max());
}

bool IsRockadierSource(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6 ||
        spellInfo->DmgClass != SPELL_DAMAGE_CLASS_RANGED)
        return false;

    if (spellInfo->Id == SPELL_ROCKET_LAUNCHER_DAMAGE)
        return spellInfo->SpellFamilyFlags == flag96(0, 0, 16777216) &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;

    for (uint32 rank : SCRAP_SHOT_RANKS)
        if (spellInfo->Id == rank)
            return spellInfo->SpellFamilyFlags == flag96(16, 0, 256) &&
                spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
                spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE;

    return false;
}

bool IsRockadierAura(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->Id != SPELL_ROCKADIER ||
        spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6)
        return false;

    SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == ROCKADIER_AURA_TYPE &&
        effect.TriggerSpell == SPELL_ROCKADIER_DAMAGE && effect.BasePoints == 99 && effect.DieSides == 1 &&
        !effect.RealPointsPerLevel && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;
}

void NormalizeRockadierCharges(SpellInfo* spellInfo)
{
    if (IsRockadierAura(spellInfo) && !spellInfo->ProcCharges)
        spellInfo->ProcCharges = 6;
}

class AscensionTinkerRockadierMetadata : public GlobalScript
{
public:
    AscensionTinkerRockadierMetadata()
        : GlobalScript("AscensionTinkerRockadierMetadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        NormalizeRockadierCharges(spellInfo);
    }
};

class aura_ascension_tinker_rockadier : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_rockadier);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_ROCKADIER_DAMAGE);
        if (!IsRockadierAura(spellInfo) || spellInfo->ProcCharges != 6 || !helper || helper->SpellFamilyName != uint32(CLASS_TINKER) + 6 ||
            helper->DmgClass != SPELL_DAMAGE_CLASS_MAGIC || helper->GetSchoolMask() != SPELL_SCHOOL_MASK_FIRE ||
            helper->MaxAffectedTargets != 10 || !helper->HasAttribute(SPELL_ATTR3_IGNORE_CASTER_MODIFIERS))
            return false;

        SpellEffectInfo const& effect = helper->Effects[EFFECT_0];
        return effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE && effect.BasePoints == 0 && effect.DieSides == 1 &&
            !effect.RealPointsPerLevel && !effect.BonusMultiplier && effect.RadiusEntry &&
            effect.RadiusEntry->RadiusMin == 8.0f && effect.RadiusEntry->RadiusMax == 8.0f && !effect.RadiusEntry->RadiusPerLevel &&
            effect.TargetA.GetTarget() == TARGET_DEST_TARGET_ENEMY && effect.TargetB.GetTarget() == TARGET_UNIT_DEST_AREA_ENEMY &&
            !helper->Effects[EFFECT_1].Effect && !helper->Effects[EFFECT_2].Effect;
    }

    bool Load() override
    {
        Unit* owner = GetUnitOwner();
        Player* player = owner ? owner->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_TINKER || GetCasterGUID() != player->GetGUID())
            return false;

        GetAura()->SetCharges(0);
        return true;
    }

    void InitializeCharges(AuraEffect const*, AuraEffectHandleModes mode)
    {
        if ((mode & AURA_EFFECT_HANDLE_REAPPLY) || !GetAura()->GetCharges())
            GetAura()->SetCharges(GetTarget()->HasAura(SPELL_ROCKET_BARRAGE) ? 10 : 6);
    }

    bool CheckAttack(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        if (!owner || eventInfo.GetActor() != owner || !damage || damage->GetAttacker() != owner ||
            !damage->GetVictim() || damage->GetVictim() == owner ||
            eventInfo.GetActionTarget() != damage->GetVictim() || !CanCopyRockadierDamage(damage->GetDamage()) ||
            damage->GetDamageType() != SPELL_DIRECT_DAMAGE || !spell || spell->GetCaster() != owner ||
            damage->GetSpellInfo() != spell->GetSpellInfo() || !IsRockadierSource(damage->GetSpellInfo()) ||
            GetAura()->IsExpired())
            return false;

        return const_cast<Spell*>(spell)->TryMarkScriptEventHandled(ROCKADIER_ATTACK_EVENT);
    }

    void CopyDamage(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!damage || !damage->GetVictim() || !CanCopyRockadierDamage(damage->GetDamage()))
            return;

        GetTarget()->CastCustomSpell(SPELL_ROCKADIER_DAMAGE, SPELLVALUE_BASE_POINT0,
            int32(damage->GetDamage()), damage->GetVictim(), true, nullptr, effect);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_tinker_rockadier::InitializeCharges,
            EFFECT_0, ROCKADIER_AURA_TYPE, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_rockadier::CheckAttack);
        OnEffectProc += AuraEffectProcFn(aura_ascension_tinker_rockadier::CopyDamage, EFFECT_0, ROCKADIER_AURA_TYPE);
    }
};
}

void AddAscensionTinkerRockadierScripts()
{
    new AscensionTinkerRockadierMetadata();
    RegisterSpellScript(aura_ascension_tinker_rockadier);
}
