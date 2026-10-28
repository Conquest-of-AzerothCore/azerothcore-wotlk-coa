/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRunemasterBrand.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>
#include <set>

namespace
{
constexpr uint32 SPELL_RUNIC_BRAND_MARK = 712323;
constexpr uint32 SPELL_RUNIC_EXPLOSION = 712324;
constexpr uint32 SPELL_GENESIS = 500501;
constexpr uint32 SPELL_GENESIS_DAMAGE = 500502;
constexpr uint32 SPELL_FRIGID_FUSION = 803225;
constexpr uint32 SPELL_FRIGID_FUSION_DAMAGE = 572338;
constexpr uint32 SPELL_FRIGID_ELEMENTS = 707654;
constexpr uint32 SPELL_FIRE_ENGRAVING = 653211;
constexpr uint32 SPELL_FIREBRAND = 653210;
constexpr uint32 SPELL_WATER_ENGRAVING = 653214;
constexpr uint32 SPELL_WATER_ENGRAVING_DRAIN = 653261;
constexpr uint32 SPELL_ICE_ENGRAVING = 653266;
constexpr uint32 SPELL_ICE_ENGRAVING_STRIKE = 653217;
constexpr uint32 SPELL_ARCANE_ENGRAVING = 653267;
constexpr uint32 SPELL_ARCANE_ENGRAVING_MARK = 653263;

struct WeaponEngraving
{
    uint32 Aura;
    uint32 Effect;
};

constexpr WeaponEngraving WeaponEngravings[] =
{
    {SPELL_FIRE_ENGRAVING, SPELL_FIREBRAND},
    {SPELL_WATER_ENGRAVING, SPELL_WATER_ENGRAVING_DRAIN},
    {SPELL_ICE_ENGRAVING, SPELL_ICE_ENGRAVING_STRIKE},
    {SPELL_ARCANE_ENGRAVING, SPELL_ARCANE_ENGRAVING_MARK}
};

bool IsRunemaster(Unit const* unit)
{
    return unit && unit->IsPlayer() && unit->getClass() == CLASS_SPIRIT_MAGE;
}

bool IsRunicBrand(uint32 id)
{
    return id == 712299 || (id >= 712301 && id <= 712307);
}

bool IsBrandRuneblade(uint32 id)
{
    return id == 707141 || (id >= 707143 && id <= 707148) || (id >= 573444 && id <= 573447);
}

class spell_ascension_runemaster_brand : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_brand);

    bool Validate(SpellInfo const* info) override
    {
        return info && IsRunicBrand(info->Id) && info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 &&
            info->Effects[EFFECT_2].Effect == SPELL_EFFECT_TRIGGER_SPELL &&
            info->Effects[EFFECT_2].TriggerSpell == SPELL_RUNIC_BRAND_MARK &&
            ValidateSpellInfo({SPELL_RUNIC_BRAND_MARK});
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_SPIRIT_MAGE;
    }

    void PreventEarlyMark(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void MarkSuccessfulTarget()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || target == caster || caster->IsFriendlyTo(target) || !_marked.insert(target->GetGUID()).second)
            return;

        caster->CastSpell(target, SPELL_RUNIC_BRAND_MARK, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_runemaster_brand::PreventEarlyMark,
            EFFECT_2, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_brand::PreventEarlyMark,
            EFFECT_2, SPELL_EFFECT_TRIGGER_SPELL);
        AfterHit += SpellHitFn(spell_ascension_runemaster_brand::MarkSuccessfulTarget);
    }

    std::set<ObjectGuid> _marked;
};

class spell_ascension_runemaster_brand_runeblade : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_brand_runeblade);

    bool Validate(SpellInfo const* info) override
    {
        return info && IsBrandRuneblade(info->Id) && info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            info->Effects[EFFECT_1].Effect == SPELL_EFFECT_TRIGGER_SPELL &&
            info->Effects[EFFECT_1].TriggerSpell == SPELL_RUNIC_EXPLOSION &&
            ValidateSpellInfo({SPELL_RUNIC_BRAND_MARK, SPELL_RUNIC_EXPLOSION});
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_SPIRIT_MAGE;
    }

    void PreventUnconditionalExplosion(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void SpendMarkOnSuccessfulHit(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || target == caster || caster->IsFriendlyTo(target) || !_processed.insert(target->GetGUID()).second)
            return;

        Unit* damageCaster = GetOriginalCaster();
        if (target->IsImmunedToDamage(damageCaster ? damageCaster : caster, GetSpellInfo()))
            return;

        Aura* mark = target->GetAura(SPELL_RUNIC_BRAND_MARK, caster->GetGUID());
        if (!mark || !mark->IsUsingCharges() || !mark->GetCharges())
            return;

        mark->ModCharges(-1);
        _pending.insert(target->GetGUID());
    }

    void ExplodeAfterHit()
    {
        Unit* target = GetHitUnit();
        if (!target || !_pending.erase(target->GetGUID()))
            return;

        GetCaster()->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
            SPELL_RUNIC_EXPLOSION, true);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_runemaster_brand_runeblade::PreventUnconditionalExplosion,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_brand_runeblade::PreventUnconditionalExplosion,
            EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_runemaster_brand_runeblade::SpendMarkOnSuccessfulHit,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_ascension_runemaster_brand_runeblade::ExplodeAfterHit);
    }

    std::set<ObjectGuid> _processed;
    std::set<ObjectGuid> _pending;
};

class runemaster_genesis_accumulation : public UnitScript
{
public:
    runemaster_genesis_accumulation() : UnitScript("runemaster_genesis_accumulation", true, {UNITHOOK_ON_DAMAGE}) { }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        if (!damage || !victim || attacker == victim || !IsRunemaster(attacker))
            return;
        for (uint32 spell : {SPELL_GENESIS, SPELL_FRIGID_FUSION})
            if (Aura* accumulator = victim->GetAura(spell, attacker->GetGUID()))
                accumulator->SetScriptValue(spell, accumulator->GetScriptValue(spell) + damage);
    }
};

class aura_ascension_runemaster_genesis : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_genesis);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_GENESIS_DAMAGE});
    }

    void Unleash(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE || !IsRunemaster(caster) ||
            !caster->IsAlive() || !target->IsAlive())
            return;
        uint64 const amount = GetAura()->GetScriptValue(SPELL_GENESIS) *
            std::clamp(GetSpellInfo()->Effects[EFFECT_1].MiscValueB, 0, 100) / 100;
        if (amount)
            caster->CastCustomSpell(SPELL_GENESIS_DAMAGE, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), target, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_runemaster_genesis::Unleash, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_runemaster_frigid_fusion : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_frigid_fusion);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_FRIGID_FUSION_DAMAGE, SPELL_FRIGID_ELEMENTS});
    }

    void Release(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE || !IsRunemaster(caster) ||
            !caster->IsAlive() || !target->IsAlive())
            return;
        int32 percent = GetSpellInfo()->Effects[EFFECT_1].MiscValueB;
        if (AuraEffect const* elements = caster->GetAuraEffect(SPELL_FRIGID_ELEMENTS, EFFECT_2))
            percent += elements->GetAmount();
        uint64 const amount = GetAura()->GetScriptValue(SPELL_FRIGID_FUSION) * std::clamp(percent, 0, 100) / 100;
        if (amount)
            caster->CastCustomSpell(SPELL_FRIGID_FUSION_DAMAGE, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), target, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_runemaster_frigid_fusion::Release, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_runemaster_genesis_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_genesis_damage);

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void TriggerWeaponEngraving()
    {
        Unit* target = GetHitUnit();
        if (!target || GetHitDamage() <= 0)
            return;
        TriggerRunemasterWeaponEngravings(GetCaster(), target);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_runemaster_genesis_damage::TriggerWeaponEngraving);
    }
};

void ApplyGenesisContracts(SpellInfo* info)
{
    SpellEffectInfo const& brand = info->Effects[EFFECT_0];
    SpellEffectInfo& accumulation = info->Effects[EFFECT_1];
    if (info->Id == SPELL_GENESIS && accumulation.IsAura(SPELL_AURA_SCHOOL_ABSORB) && accumulation.MiscValueB == 50 &&
        brand.IsAura(SPELL_AURA_DUMMY) && brand.TriggerSpell == SPELL_GENESIS_DAMAGE)
        accumulation.ApplyAuraName = SPELL_AURA_DUMMY;

    if (info->Id == SPELL_GENESIS_DAMAGE && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
        !info->Effects[EFFECT_1].Effect && !info->Effects[EFFECT_2].Effect)
    {
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
        info->AscensionInheritsResolvedAmount = true;
        info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
    }
}

void ApplyFrigidFusionContracts(SpellInfo* info)
{
    SpellEffectInfo const& fusion = info->Effects[EFFECT_0];
    SpellEffectInfo& accumulation = info->Effects[EFFECT_1];
    if (info->Id == SPELL_FRIGID_FUSION && accumulation.IsAura(SPELL_AURA_SCHOOL_ABSORB) &&
        accumulation.MiscValueB == 20 && fusion.IsAura(SPELL_AURA_DUMMY) &&
        fusion.TriggerSpell == SPELL_FRIGID_FUSION_DAMAGE)
        accumulation.ApplyAuraName = SPELL_AURA_DUMMY;

    if (info->Id == SPELL_FRIGID_FUSION_DAMAGE && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
    {
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AscensionInheritsResolvedAmount = true;
        info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
    }
}
}

void TriggerRunemasterWeaponEngravings(Unit* caster, Unit* target)
{
    for (WeaponEngraving const& engraving : WeaponEngravings)
        if (target->IsAlive() && caster->HasAura(engraving.Aura, caster->GetGUID()))
            caster->CastSpell(target, engraving.Effect, TRIGGERED_FULL_MASK);
}

void ApplyAscensionRunemasterBrandContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != uint32(CLASS_SPIRIT_MAGE) + 6)
        return;

    ApplyGenesisContracts(info);
    ApplyFrigidFusionContracts(info);

    SpellEffectInfo& fistBonus = info->Effects[EFFECT_1];
    if (info->Id == SPELL_FIRE_ENGRAVING && fistBonus.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
        fistBonus.MiscValue == SPELLMOD_DAMAGE && !fistBonus.SpellClassMask)
        fistBonus.SpellClassMask = flag96(0, 0, 0x00008000);

    SpellEffectInfo& effect = info->Effects[EFFECT_0];
    if (info->Id == SPELL_RUNIC_BRAND_MARK && !info->ProcFlags && !info->ProcCharges && !info->StackAmount &&
        effect.IsAura(SPELL_AURA_DUMMY) && effect.TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
        !effect.TargetB.GetTarget() && info->SpellFamilyFlags == flag96(1048576, 0, 0) &&
        !info->Effects[EFFECT_1].Effect && !info->Effects[EFFECT_2].Effect)
        info->ProcCharges = 1;

    if (info->Id == SPELL_RUNIC_EXPLOSION && effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
        effect.TargetA.GetTarget() == TARGET_DEST_TARGET_ENEMY && effect.TargetB.GetTarget() == TARGET_UNIT_DEST_AREA_ENEMY &&
        info->SchoolMask == SPELL_SCHOOL_MASK_FIRE && info->SpellFamilyFlags == flag96(0, 32, 0) &&
        !info->Effects[EFFECT_1].Effect && !info->Effects[EFFECT_2].Effect)
    {
        info->SchoolMask = SPELL_SCHOOL_MASK_FIRE | SPELL_SCHOOL_MASK_ARCANE;
        effect.TargetA = SpellImplicitTargetInfo(TARGET_DEST_DEST);
        info->_InitializeExplicitTargetMask();
    }
}

void AddAscensionRunemasterBrandScripts()
{
    RegisterSpellScript(spell_ascension_runemaster_brand);
    RegisterSpellScript(spell_ascension_runemaster_brand_runeblade);
    new runemaster_genesis_accumulation();
    RegisterSpellScript(aura_ascension_runemaster_genesis);
    RegisterSpellScript(aura_ascension_runemaster_frigid_fusion);
    RegisterSpellScript(spell_ascension_runemaster_genesis_damage);
}
