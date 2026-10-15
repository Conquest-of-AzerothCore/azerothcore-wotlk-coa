/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionVenomancerVenomTalents.h"
#include "AscensionVenomancerVenomData.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <limits>

namespace
{
constexpr uint32 SPELL_INTOXICATING = 706023;
constexpr uint32 SPELL_BLIGHT = 805776;
constexpr int32 SPORE_EXTENSION = 4000;

bool IsFamily(SpellInfo const* info, uint32 id)
{
    return info && info->Id == id && info->SpellFamilyName == uint32(CLASS_PROPHET) + 6;
}

bool IsSelfModifier(SpellEffectInfo const& effect, AuraType type, int32 base, int32 operation, flag96 mask)
{
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == type &&
        effect.BasePoints == base && effect.DieSides == 1 && !effect.RealPointsPerLevel &&
        effect.MiscValue == operation && !effect.MiscValueB && effect.SpellClassMask == mask &&
        !effect.Amplitude && !effect.TriggerSpell && effect.TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !effect.TargetB.GetTarget();
}

void NormalizeVenomics(SpellInfo* info)
{
    if (!IsFamily(info, 705975) || info->SpellFamilyFlags || info->Effects[EFFECT_2].Effect ||
        !IsSelfModifier(info->Effects[EFFECT_0], SPELL_AURA_ADD_PCT_MODIFIER, 29, SPELLMOD_EFFECT1,
            flag96(0, 32768, 0)) ||
        !IsSelfModifier(info->Effects[EFFECT_1], SPELL_AURA_DUMMY, 1, 0, flag96(0, 0, 0)))
        return;

    info->Effects[EFFECT_0].MiscValue = SPELLMOD_ALL_EFFECTS;
    SpellEffectInfo& coefficient = info->Effects[EFFECT_1];
    coefficient.ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
    coefficient.BasePoints = 29;
    coefficient.MiscValue = SPELLMOD_BONUS_MULTIPLIER;
    coefficient.SpellClassMask = flag96(0, 32768, 0);
}

bool IsIntoxicating(SpellInfo const* info)
{
    if (!IsFamily(info, SPELL_INTOXICATING) || info->SpellFamilyFlags || info->ProcFlags ||
        !IsSelfModifier(info->Effects[EFFECT_0], SPELL_AURA_ADD_FLAT_MODIFIER, -21, SPELLMOD_EFFECT2,
            flag96(0, 64, 0)) ||
        !IsSelfModifier(info->Effects[EFFECT_2], SPELL_AURA_ADD_FLAT_MODIFIER, 0, SPELLMOD_EFFECT2,
            flag96(0, 2, 0)))
        return false;

    SpellEffectInfo const& effect = info->Effects[EFFECT_1];
    return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.ApplyAuraName == SPELL_AURA_PROC_TRIGGER_SPELL &&
        effect.TriggerSpell == 706454 && !effect.BasePoints && !effect.DieSides &&
        effect.TargetA.GetTarget() == TARGET_UNIT_CASTER && !effect.TargetB.GetTarget();
}

Player* Venomancer(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_PROPHET ? player : nullptr;
}

Aura* OwnAura(Player* player, uint32 id)
{
    Aura* aura = player->GetOwnedAura(id, player->GetGUID());
    return aura && !aura->IsRemoved() && !aura->IsExpired() ? aura : nullptr;
}

bool CanExtend(Player* player)
{
    if (!player)
        return false;

    Aura* talent = OwnAura(player, SPELL_INTOXICATING);
    Aura* blight = OwnAura(player, SPELL_BLIGHT);
    return talent && IsIntoxicating(talent->GetSpellInfo()) && blight &&
        IsFamily(blight->GetSpellInfo(), SPELL_BLIGHT) &&
        blight->GetSpellInfo()->SpellFamilyFlags == flag96(0, 0, 268435456) &&
        blight->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell == 805896;
}

void RefreshMycosisModifiers(Player* player)
{
    if (!player || player->getClass() != CLASS_PROPHET)
        return;

    for (uint32 id : {805731u, 805775u})
        if (Aura* aura = OwnAura(player, id))
        {
            SpellInfo const* info = aura->GetSpellInfo();
            AuraType const type = id == 805731 ? SPELL_AURA_ADD_PCT_MODIFIER : SPELL_AURA_ADD_FLAT_MODIFIER;
            int32 const operation = id == 805731 ? SPELLMOD_CASTING_TIME : SPELLMOD_JUMP_TARGETS;
            if (IsFamily(info, id) && IsSelfModifier(info->Effects[EFFECT_1], type, -1, operation,
                    flag96(0, 32, 0)))
                if (AuraEffect* effect = aura->GetEffect(EFFECT_1))
                    effect->RecalculateAmount();
        }
}

bool IsRank(SpellInfo const* info, AscensionVenomancerVenomData::Rank const& rank, bool spore)
{
    if (!IsFamily(info, rank.Id) || info->SpellFamilyFlags != flag96(0, spore ? 8 : 32, 0))
        return false;

    SpellEffectInfo const& effect = info->Effects[EFFECT_0];
    return effect.Effect == (spore ? SPELL_EFFECT_APPLY_AURA : SPELL_EFFECT_SCHOOL_DAMAGE) &&
        effect.ApplyAuraName == (spore ? SPELL_AURA_PERIODIC_DAMAGE : SPELL_AURA_NONE) &&
        effect.BasePoints == rank.BasePoints && effect.DieSides == rank.DieSides &&
        effect.RealPointsPerLevel == rank.PointsPerLevel && effect.Amplitude == (spore ? 3000u : 0u) &&
        effect.ChainTarget == (spore ? 0u : 1u) && effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
        !effect.TargetB.GetTarget();
}

bool IsMycosis(SpellInfo const* info)
{
    for (auto const& rank : AscensionVenomancerVenomData::MYCOSIS)
        if (IsRank(info, rank, false))
            return true;

    return false;
}

void ExtendOwnSpore(Player* player, Unit* target)
{
    if (!CanExtend(player) || !target || target == player || !player->IsValidAttackTarget(target))
        return;

    for (auto const& rank : AscensionVenomancerVenomData::SPORE)
        if (Aura* aura = target->GetAura(rank.Id, player->GetGUID()))
        {
            if (aura->IsRemoved() || aura->IsExpired() || !IsRank(aura->GetSpellInfo(), rank, true))
                continue;

            int32 const remaining = aura->GetDuration();
            int32 const maximum = aura->GetMaxDuration();
            if (remaining <= 0 || maximum <= 0 ||
                remaining > std::numeric_limits<int32>::max() - SPORE_EXTENSION ||
                maximum > std::numeric_limits<int32>::max() - SPORE_EXTENSION)
                continue;

            aura->SetMaxDuration(maximum + SPORE_EXTENSION);
            aura->SetDuration(remaining + SPORE_EXTENSION);
        }
}

class AscensionVenomancerVenomTalentMetadata : public GlobalScript
{
public:
    AscensionVenomancerVenomTalentMetadata()
        : GlobalScript("AscensionVenomancerVenomTalentMetadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        NormalizeVenomics(info);
    }
};

class AscensionVenomancerIntoxicatingLifecycle : public UnitScript
{
public:
    AscensionVenomancerIntoxicatingLifecycle()
        : UnitScript("AscensionVenomancerIntoxicatingLifecycle", true,
            {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = Venomancer(unit);
        if (player && aura && aura->GetCasterGUID() == player->GetGUID() && IsIntoxicating(aura->GetSpellInfo()))
            RefreshMycosisModifiers(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = Venomancer(unit);
        Aura* aura = application ? application->GetBase() : nullptr;
        if (player && aura && aura->GetCasterGUID() == player->GetGUID() && IsIntoxicating(aura->GetSpellInfo()))
            RefreshMycosisModifiers(player);
    }
};

class AscensionVenomancerIntoxicatingLogin : public PlayerScript
{
public:
    AscensionVenomancerIntoxicatingLogin()
        : PlayerScript("AscensionVenomancerIntoxicatingLogin", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        RefreshMycosisModifiers(player);
    }
};

class spell_ascension_venomancer_intoxicating_mycosis : public SpellScript
{
    PrepareSpellScript(spell_ascension_venomancer_intoxicating_mycosis);
    bool _damageEffectHit = false;

    bool Validate(SpellInfo const* info) override
    {
        return IsMycosis(info);
    }

    void ResetHit(SpellMissInfo)
    {
        _damageEffectHit = false;
    }

    void RecordHit(SpellEffIndex)
    {
        _damageEffectHit = true;
    }

    void Extend()
    {
        Player* player = Venomancer(GetCaster());
        if (_damageEffectHit && player && GetOriginalCaster() == player && IsMycosis(GetSpellInfo()))
            ExtendOwnSpore(player, GetHitUnit());
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_ascension_venomancer_intoxicating_mycosis::ResetHit);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_venomancer_intoxicating_mycosis::RecordHit,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_ascension_venomancer_intoxicating_mycosis::Extend);
    }
};

class spell_ascension_venomancer_intoxicating_extension : public SpellScript
{
    PrepareSpellScript(spell_ascension_venomancer_intoxicating_extension);

    bool Validate(SpellInfo const* info) override
    {
        if (!IsFamily(info, 706454) || info->SpellFamilyFlags ||
            info->Effects[EFFECT_1].Effect || info->Effects[EFFECT_2].Effect)
            return false;

        SpellEffectInfo const& effect = info->Effects[EFFECT_0];
        return effect.Effect == SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION && effect.BasePoints == 3999 &&
            effect.DieSides == 1 && !effect.RealPointsPerLevel && effect.MiscValue == 804983 &&
            !effect.MiscValueB && effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
            !effect.TargetB.GetTarget();
    }

    void Extend(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = Venomancer(GetCaster());
        if (player && GetOriginalCaster() == player && Validate(GetSpellInfo()))
            ExtendOwnSpore(player, GetHitUnit());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_venomancer_intoxicating_extension::Extend,
            EFFECT_0, SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION);
    }
};
}

void AddAscensionVenomancerVenomTalentScripts()
{
    new AscensionVenomancerVenomTalentMetadata();
    new AscensionVenomancerIntoxicatingLifecycle();
    new AscensionVenomancerIntoxicatingLogin();
    RegisterSpellScript(spell_ascension_venomancer_intoxicating_mycosis);
    RegisterSpellScript(spell_ascension_venomancer_intoxicating_extension);
}
