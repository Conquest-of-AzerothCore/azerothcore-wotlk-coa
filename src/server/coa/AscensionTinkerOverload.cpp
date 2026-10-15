/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTinkerOverload.h"
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
constexpr uint32 SPELL_OVERLOAD = 707403;
constexpr uint32 SPELL_EXTENDER = 681003;
constexpr uint32 SPELL_MECHANICAL_ARM = 681002;
constexpr uint32 SPELL_ARM_REMOVER = 681000;
constexpr uint32 SPELL_OVERLOAD_FIRST = 705798;
constexpr uint32 SPELL_OVERLOAD_SECOND = 707469;
constexpr uint32 SPELL_COMBUSTION_DAMAGE = 801388;
constexpr uint32 SPELL_ACTIVATE_JETS = 801389;
constexpr AuraType OVERLOAD_COPY_AURA = AuraType(354);
constexpr std::array<uint32, 7> SCRAP_SHOT_RANKS = {500549, 500556, 500557, 500558, 500559, 500560, 500561};
constexpr std::array<uint32, 7> COMBUSTION_RANKS = {801387, 803439, 803440, 803441, 803442, 803443, 803444};
constexpr std::array<uint32, 6> LASER_BEAM_RANKS = {805372, 807287, 807288, 807289, 807290, 807291};

bool IsTinkerSpell(SpellInfo const* spellInfo, uint32 id)
{
    return spellInfo && spellInfo->Id == id && spellInfo->SpellFamilyName == uint32(CLASS_TINKER) + 6;
}

bool IsSelfAura(SpellEffectInfo const& effect, AuraType type, int32 base, uint32 trigger,
    int32 operation = 0, flag96 const& mask = flag96())
{
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == type &&
        effect.BasePoints == base && effect.DieSides == 1 && !effect.RealPointsPerLevel &&
        effect.TriggerSpell == trigger && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !effect.TargetB.GetTarget() && !effect.Amplitude && effect.MiscValue == operation &&
        !effect.MiscValueB && effect.SpellClassMask == mask;
}

bool IsOverloadAura(SpellInfo const* spellInfo, int32 secondBase)
{
    return IsTinkerSpell(spellInfo, SPELL_OVERLOAD) && spellInfo->SpellFamilyFlags == flag96(4096, 0, 0) &&
        spellInfo->IsPassive() && spellInfo->GetDuration() == -1 && spellInfo->ProcChance == 40 &&
        !spellInfo->ProcFlags && !spellInfo->ProcCharges && !spellInfo->StackAmount &&
        IsSelfAura(spellInfo->Effects[EFFECT_0], SPELL_AURA_PROC_TRIGGER_SPELL, 9, SPELL_ARM_REMOVER) &&
        IsSelfAura(spellInfo->Effects[EFFECT_1], OVERLOAD_COPY_AURA, 29, SPELL_OVERLOAD_FIRST, 3) &&
        IsSelfAura(spellInfo->Effects[EFFECT_2], OVERLOAD_COPY_AURA, secondBase, SPELL_OVERLOAD_SECOND, 3);
}

bool IsMechanicalArm(SpellInfo const* spellInfo, AuraType secondType)
{
    return IsTinkerSpell(spellInfo, SPELL_MECHANICAL_ARM) && !spellInfo->SpellFamilyFlags &&
        spellInfo->GetDuration() == 10000 && spellInfo->StackAmount == 10 &&
        !spellInfo->ProcFlags && !spellInfo->ProcChance && !spellInfo->ProcCharges &&
        IsSelfAura(spellInfo->Effects[EFFECT_0], SPELL_AURA_ADD_FLAT_MODIFIER, 2, 0,
            SPELLMOD_CHANCE_OF_SUCCESS, flag96(4096, 0, 0)) &&
        IsSelfAura(spellInfo->Effects[EFFECT_1], secondType, 1, 0, SPELLMOD_DAMAGE, flag96(0, 536870912, 0)) &&
        !spellInfo->Effects[EFFECT_2].Effect;
}

bool IsLaserBeam(SpellInfo const* spellInfo)
{
    return spellInfo && spellInfo->SpellFamilyName == uint32(CLASS_TINKER) + 6 &&
        std::find(LASER_BEAM_RANKS.begin(), LASER_BEAM_RANKS.end(), spellInfo->Id) != LASER_BEAM_RANKS.end() &&
        spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED && spellInfo->GetSchoolMask() == SPELL_SCHOOL_MASK_FIRE &&
        spellInfo->SpellFamilyFlags == flag96(134217728, 0, 0) && spellInfo->Speed == 40.0f &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
        spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_SCRIPT_EFFECT &&
        spellInfo->Effects[EFFECT_2].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE;
}

bool IsOverloadSource(SpellInfo const* spellInfo)
{
    if (IsLaserBeam(spellInfo))
        return true;

    return IsTinkerSpell(spellInfo, SPELL_COMBUSTION_DAMAGE) &&
        spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED && spellInfo->GetSchoolMask() == SPELL_SCHOOL_MASK_FIRE &&
        spellInfo->SpellFamilyFlags == flag96(0, 4096, 16384) && spellInfo->Speed == 30.0f &&
        spellInfo->HasAttribute(SPELL_ATTR3_NOT_A_PROC) &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;
}

bool IsExtenderCast(SpellInfo const* spellInfo)
{
    if (!spellInfo || spellInfo->SpellFamilyName != uint32(CLASS_TINKER) + 6)
        return false;

    if (IsLaserBeam(spellInfo))
        return true;

    if (spellInfo->Id == SPELL_ACTIVATE_JETS)
        return spellInfo->DmgClass == SPELL_DAMAGE_CLASS_MAGIC && spellInfo->SpellFamilyFlags == flag96(268435456, 0, 0) &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_LEAP_BACK &&
            spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_APPLY_AURA &&
            spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_FEATHER_FALL &&
            spellInfo->Effects[EFFECT_2].Effect == SPELL_EFFECT_APPLY_AURA &&
            spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL &&
            spellInfo->Effects[EFFECT_2].TriggerSpell == 801399 && spellInfo->Effects[EFFECT_2].Amplitude == 250;

    if (spellInfo->DmgClass != SPELL_DAMAGE_CLASS_RANGED)
        return false;

    if (std::find(SCRAP_SHOT_RANKS.begin(), SCRAP_SHOT_RANKS.end(), spellInfo->Id) != SCRAP_SHOT_RANKS.end())
        return spellInfo->SpellFamilyFlags == flag96(16, 0, 256) &&
            spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG &&
            spellInfo->Effects[EFFECT_1].Effect == SPELL_EFFECT_WEAPON_PERCENT_DAMAGE &&
            spellInfo->Effects[EFFECT_2].Effect == SPELL_EFFECT_DUMMY;

    return std::find(COMBUSTION_RANKS.begin(), COMBUSTION_RANKS.end(), spellInfo->Id) != COMBUSTION_RANKS.end() &&
        spellInfo->SpellFamilyFlags == flag96(0, 0, 1073745920) &&
        spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE &&
        spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_COMBUSTION_DAMAGE &&
        !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;
}

bool IsDamageHelper(SpellInfo const* spellInfo, uint32 id)
{
    if (!IsTinkerSpell(spellInfo, id) || spellInfo->SpellFamilyFlags || spellInfo->Speed ||
        spellInfo->DmgClass != SPELL_DAMAGE_CLASS_MELEE || spellInfo->GetSchoolMask() != SPELL_SCHOOL_MASK_NORMAL ||
        !spellInfo->HasAttribute(SPELL_ATTR2_CANT_CRIT) || !spellInfo->HasAttribute(SPELL_ATTR3_IGNORE_CASTER_MODIFIERS) ||
        !spellInfo->HasAttribute(SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS) ||
        !spellInfo->HasAttribute(SPELL_ATTR6_IGNORE_CASTER_DAMAGE_MODIFIERS))
        return false;

    SpellEffectInfo const& effect = spellInfo->Effects[EFFECT_0];
    return effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE && effect.BasePoints == 0 && effect.DieSides == 1 &&
        !effect.RealPointsPerLevel && !effect.BonusMultiplier && effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
        !effect.TargetB.GetTarget() && !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect;
}

bool IsSelfOwnedTinker(Unit* owner, ObjectGuid caster)
{
    Player* player = owner ? owner->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_TINKER && caster == player->GetGUID();
}

int32 OverloadDamage(uint32 damage, int32 percent)
{
    if (percent <= 0)
        return 0;

    uint64 const amount = uint64(damage) * uint32(percent) / 100;
    if (!amount || double(float(amount)) > double(std::numeric_limits<int32>::max()))
        return 0;

    return int32(amount);
}

class aura_ascension_tinker_overload : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_overload);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* remover = sSpellMgr->GetSpellInfo(SPELL_ARM_REMOVER);
        return IsOverloadAura(spellInfo, 29) && IsMechanicalArm(sSpellMgr->GetSpellInfo(SPELL_MECHANICAL_ARM), SPELL_AURA_DUMMY) &&
            IsDamageHelper(sSpellMgr->GetSpellInfo(SPELL_OVERLOAD_FIRST), SPELL_OVERLOAD_FIRST) &&
            IsDamageHelper(sSpellMgr->GetSpellInfo(SPELL_OVERLOAD_SECOND), SPELL_OVERLOAD_SECOND) &&
            IsTinkerSpell(remover, SPELL_ARM_REMOVER) && !remover->Speed &&
            remover->Effects[EFFECT_0].Effect == SPELL_EFFECT_REMOVE_AURA &&
            remover->Effects[EFFECT_0].TriggerSpell == SPELL_MECHANICAL_ARM &&
            remover->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
            !remover->Effects[EFFECT_1].Effect && !remover->Effects[EFFECT_2].Effect;
    }

    bool Load() override
    {
        return GetUnitOwner() != nullptr;
    }

    bool CheckDamage(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        return IsSelfOwnedTinker(owner, GetCasterGUID()) && eventInfo.GetActor() == owner && damage && damage->GetAttacker() == owner &&
            damage->GetVictim() && damage->GetVictim() != owner && !owner->IsFriendlyTo(damage->GetVictim()) &&
            eventInfo.GetActionTarget() == damage->GetVictim() && damage->GetDamage() &&
            damage->GetDamageType() == SPELL_DIRECT_DAMAGE && spell && spell->GetCaster() == owner &&
            spell->GetSpellInfo() == damage->GetSpellInfo() && IsOverloadSource(damage->GetSpellInfo()) &&
            !GetAura()->IsExpired();
    }

    void CopyDamage(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!damage || !damage->GetVictim())
            return;

        int32 const amount = OverloadDamage(damage->GetDamage(), effect->GetAmount());
        if (!amount)
            return;

        GetTarget()->CastCustomSpell(effect->GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell,
            SPELLVALUE_BASE_POINT0, amount, damage->GetVictim(), true, nullptr, effect, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_overload::CheckDamage);
        OnEffectProc += AuraEffectProcFn(aura_ascension_tinker_overload::CopyDamage, EFFECT_1, OVERLOAD_COPY_AURA);
        OnEffectProc += AuraEffectProcFn(aura_ascension_tinker_overload::CopyDamage, EFFECT_2, OVERLOAD_COPY_AURA);
    }
};

class aura_ascension_tinker_extender : public AuraScript
{
    PrepareAuraScript(aura_ascension_tinker_extender);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return IsTinkerSpell(spellInfo, SPELL_EXTENDER) && spellInfo->IsPassive() && spellInfo->GetDuration() == -1 &&
            spellInfo->ProcChance == 100 && !spellInfo->ProcFlags && !spellInfo->ProcCharges &&
            !spellInfo->StackAmount && !spellInfo->SpellFamilyFlags &&
            IsSelfAura(spellInfo->Effects[EFFECT_0], SPELL_AURA_PROC_TRIGGER_SPELL, -1, SPELL_MECHANICAL_ARM) &&
            !spellInfo->Effects[EFFECT_1].Effect && !spellInfo->Effects[EFFECT_2].Effect &&
            IsMechanicalArm(sSpellMgr->GetSpellInfo(SPELL_MECHANICAL_ARM), SPELL_AURA_DUMMY);
    }

    bool Load() override
    {
        return GetUnitOwner() != nullptr;
    }

    bool CheckCast(ProcEventInfo& eventInfo)
    {
        Spell const* spell = eventInfo.GetProcSpell();
        return IsSelfOwnedTinker(GetTarget(), GetCasterGUID()) && eventInfo.GetActor() == GetTarget() &&
            spell && spell->GetCaster() == GetTarget() &&
            !spell->IsTriggered() && IsExtenderCast(spell->GetSpellInfo()) && !GetAura()->IsExpired();
    }

    void RemoveArm(AuraEffect const*, AuraEffectHandleModes)
    {
        if (IsSelfOwnedTinker(GetTarget(), GetCasterGUID()))
            GetTarget()->RemoveAurasDueToSpell(SPELL_MECHANICAL_ARM, GetCasterGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_tinker_extender::CheckCast);
        AfterEffectRemove += AuraEffectApplyFn(aura_ascension_tinker_extender::RemoveArm,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class AscensionTinkerExtenderLogin : public PlayerScript
{
public:
    AscensionTinkerExtenderLogin() : PlayerScript("AscensionTinkerExtenderLogin", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        if (player && player->getClass() == CLASS_TINKER &&
            (!player->HasSpell(SPELL_EXTENDER) || !player->HasAura(SPELL_EXTENDER, player->GetGUID())))
            player->RemoveAurasDueToSpell(SPELL_MECHANICAL_ARM, player->GetGUID());
    }
};
}

void ApplyAscensionTinkerOverloadMetadata(SpellInfo* spellInfo)
{
    if (IsOverloadAura(spellInfo, 24))
        spellInfo->Effects[EFFECT_2].BasePoints = 29;

    if (IsMechanicalArm(spellInfo, SPELL_AURA_ADD_PCT_MODIFIER))
        spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
}

void AddAscensionTinkerOverloadScripts()
{
    RegisterSpellScript(aura_ascension_tinker_overload);
    RegisterSpellScript(aura_ascension_tinker_extender);
    new AscensionTinkerExtenderLogin();
}
