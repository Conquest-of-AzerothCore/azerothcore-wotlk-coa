/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRunemasterGlyphs.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <array>

namespace
{
constexpr uint32 SPELL_FROST_GLYPH_PASSIVE = 92152;
constexpr uint32 SPELL_FLAME_GLYPH_PASSIVE = 705625;
constexpr uint32 SPELL_ARCANE_GLYPH_PASSIVE = 805727;
constexpr uint32 SPELL_FROST_GLYPH = 520090;
constexpr uint32 SPELL_FLAME_GLYPH = 520091;
constexpr uint32 SPELL_ARCANE_GLYPH = 520092;
constexpr uint32 SPELL_UNLEASHED_FROST = 520096;
constexpr uint32 SPELL_UNLEASHED_FLAME = 520097;
constexpr uint32 SPELL_UNLEASHED_ARCANE = 520098;
constexpr uint32 SPELL_GLYPHIC_OVERLOAD = 520099;
constexpr uint32 SPELL_OVERLOADED_FLAME = 520107;
constexpr uint32 SPELL_OVERLOADED_FROST = 520108;
constexpr uint32 SPELL_OVERLOADED_CHILL = 520109;
constexpr uint32 SPELL_UNLEASHED_CHILL = 520110;
constexpr uint32 SPELL_SCROLL_PASSIVE = 802204;
constexpr uint32 SPELL_SCROLL_BUFF = 520077;
constexpr uint32 SPELL_PHASE_RUSH_PASSIVE = 805724;
constexpr uint32 SPELL_PHASE_RUSH_BUFF = 805725;
constexpr uint32 SPELL_UNLEASHED_POWER = 807504;
constexpr uint32 SPELL_UNLEASHED_POWER_DEBUFF = 504844;
constexpr uint32 SPELL_PRIMORDIAL_SALVOS = 800752;
constexpr uint32 SPELL_FROST_SALVO = 800730;
constexpr uint32 SPELL_FLAME_SALVO = 800729;
constexpr uint32 SPELL_ARCANE_SALVO = 800731;

void LaunchPrimordialSalvo(Unit* caster, Unit* target, uint32 salvo)
{
    if (caster->HasAura(SPELL_PRIMORDIAL_SALVOS, caster->GetGUID()) && target->IsAlive())
        caster->CastSpell(target, salvo, TRIGGERED_FULL_MASK);
}

bool IsElementalBurst(uint32 id)
{
    return id == 802202 || (id >= 502828 && id <= 502838);
}

bool IsGlyphGenerator(uint32 id)
{
    return IsElementalBurst(id) || id == 800732 || (id >= 502823 && id <= 502827);
}

bool IsThaumaturgy(uint32 id)
{
    return id == 804550 || (id >= 520071 && id <= 520076);
}

bool IsGlyphReleaser(uint32 id)
{
    return IsThaumaturgy(id) || id == 801179 || (id >= 520067 && id <= 520070) ||
        (id >= 572119 && id <= 572122);
}

bool IsGlyphHelper(uint32 id)
{
    return id == SPELL_UNLEASHED_FROST || id == SPELL_UNLEASHED_FLAME ||
        id == SPELL_UNLEASHED_ARCANE || id == SPELL_OVERLOADED_FLAME;
}

bool IsRunemaster(Unit* caster)
{
    return caster && caster->IsPlayer() && caster->getClass() == CLASS_SPIRIT_MAGE;
}

void GenerateGlyph(Unit* caster)
{
    if (!caster->HasAura(SPELL_FROST_GLYPH_PASSIVE))
        return;

    uint32 glyph = SPELL_FROST_GLYPH;
    if (caster->HasAura(SPELL_ARCANE_GLYPH_PASSIVE) && caster->HasAura(SPELL_FLAME_GLYPH, caster->GetGUID()))
        glyph = SPELL_ARCANE_GLYPH;
    else if (caster->HasAura(SPELL_FLAME_GLYPH_PASSIVE) && caster->HasAura(SPELL_FROST_GLYPH, caster->GetGUID()))
        glyph = SPELL_FLAME_GLYPH;

    caster->CastSpell(caster, glyph, TRIGGERED_FULL_MASK);
}

class spell_ascension_runemaster_glyph_cast : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_glyph_cast);

    bool Validate(SpellInfo const* info) override
    {
        return info && info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 &&
            (IsGlyphGenerator(info->Id) || IsGlyphReleaser(info->Id) || info->Id == SPELL_GLYPHIC_OVERLOAD) &&
            ValidateSpellInfo({SPELL_FROST_GLYPH, SPELL_FLAME_GLYPH, SPELL_ARCANE_GLYPH,
                SPELL_UNLEASHED_FROST, SPELL_UNLEASHED_FLAME, SPELL_UNLEASHED_ARCANE,
                SPELL_SCROLL_BUFF, SPELL_PHASE_RUSH_BUFF, SPELL_UNLEASHED_POWER_DEBUFF});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster()) && !GetSpell()->IsTriggered();
    }

    void AfterSuccessfulCast()
    {
        Unit* caster = GetCaster();
        uint32 const id = GetSpellInfo()->Id;
        if (IsGlyphGenerator(id))
            GenerateGlyph(caster);
        else if (id == SPELL_GLYPHIC_OVERLOAD && caster->HasAura(id, caster->GetGUID()))
            for (uint32 glyph : {SPELL_FROST_GLYPH, SPELL_FLAME_GLYPH, SPELL_ARCANE_GLYPH})
                caster->CastSpell(caster, glyph, TRIGGERED_FULL_MASK);

        if (IsThaumaturgy(id) && caster->HasAura(SPELL_PHASE_RUSH_PASSIVE))
            caster->CastSpell(caster, SPELL_PHASE_RUSH_BUFF, TRIGGERED_FULL_MASK);
    }

    void AfterSuccessfulHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || target == caster || caster->IsFriendlyTo(target))
            return;

        if (IsElementalBurst(GetSpellInfo()->Id) && GetHitDamage() > 0 && caster->HasAura(SPELL_UNLEASHED_POWER))
            caster->CastSpell(target, SPELL_UNLEASHED_POWER_DEBUFF, TRIGGERED_FULL_MASK);

        if (_released || !IsGlyphReleaser(GetSpellInfo()->Id))
            return;
        _released = true;

        std::array<uint32, 3> const carriers = {SPELL_FROST_GLYPH, SPELL_FLAME_GLYPH, SPELL_ARCANE_GLYPH};
        std::array<uint32, 3> const helpers = {SPELL_UNLEASHED_FROST, SPELL_UNLEASHED_FLAME, SPELL_UNLEASHED_ARCANE};
        std::array<uint32, 3> const salvos = {SPELL_FROST_SALVO, SPELL_FLAME_SALVO, SPELL_ARCANE_SALVO};
        std::array<bool, 3> active = {};
        bool any = false;
        for (std::size_t i = 0; i < carriers.size(); ++i)
        {
            active[i] = caster->HasAura(carriers[i], caster->GetGUID());
            any = any || active[i];
            if (active[i])
                caster->RemoveAurasDueToSpell(carriers[i], caster->GetGUID());
        }

        for (std::size_t i = 0; i < carriers.size(); ++i)
            if (active[i])
            {
                caster->CastSpell(target, helpers[i], TRIGGERED_FULL_MASK);
                LaunchPrimordialSalvo(caster, target, salvos[i]);
                if (caster->HasAura(SPELL_SCROLL_PASSIVE))
                    caster->CastSpell(caster, SPELL_SCROLL_BUFF, TRIGGERED_FULL_MASK);
            }

        if (any)
            caster->RemoveAurasDueToSpell(SPELL_GLYPHIC_OVERLOAD, caster->GetGUID());
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_runemaster_glyph_cast::AfterSuccessfulCast);
        AfterHit += SpellHitFn(spell_ascension_runemaster_glyph_cast::AfterSuccessfulHit);
    }

    bool _released = false;
};

class spell_ascension_runemaster_runic_obliteration_glyph : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_runic_obliteration_glyph);

    bool Load() override { return IsRunemaster(GetCaster()); }

    void Generate() { GenerateGlyph(GetCaster()); }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_runemaster_runic_obliteration_glyph::Generate);
    }
};

class spell_ascension_runemaster_glyph_payload : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_glyph_payload);

    bool Validate(SpellInfo const* info) override
    {
        return info && info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 && IsGlyphHelper(info->Id) &&
            ValidateSpellInfo({SPELL_OVERLOADED_FLAME, SPELL_OVERLOADED_FROST, SPELL_UNLEASHED_CHILL});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void PreparePayload()
    {
        Unit* caster = GetCaster();
        _overloaded = caster->HasAura(SPELL_GLYPHIC_OVERLOAD, caster->GetGUID());
        double const level = caster->GetLevel();
        double const scale = 0.0267291844060354 + 0.0048541098014737 * level +
            0.0001859597762293 * level * level;
        for (uint8 i = EFFECT_0; i < MAX_SPELL_EFFECTS; ++i)
        {
            SpellEffectInfo const& effect = GetSpellInfo()->Effects[i];
            if ((effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE && !effect.IsAura(SPELL_AURA_PERIODIC_DAMAGE)) ||
                effect.DieSides != 1 || effect.RealPointsPerLevel != 0.0f ||
                GetSpellValue()->EffectBasePoints[i] != effect.BasePoints)
                continue;

            GetSpell()->SetSpellValue(SpellValueMod(SPELLVALUE_BASE_POINT0 + i),
                int32(double(effect.BasePoints + 1) * scale));
        }
    }

    void PreventFrostRoot(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void AfterPayloadHit()
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;

        if (GetSpellInfo()->Id == SPELL_UNLEASHED_FROST)
            GetCaster()->CastSpell(target, _overloaded ? SPELL_OVERLOADED_FROST : SPELL_UNLEASHED_CHILL,
                TRIGGERED_FULL_MASK);
        else if (GetSpellInfo()->Id == SPELL_UNLEASHED_FLAME && _overloaded)
            GetCaster()->CastSpell(target, SPELL_OVERLOADED_FLAME, TRIGGERED_FULL_MASK);
    }

    void PreventRepeatedFlameChains(std::list<WorldObject*>& targets)
    {
        if (GetSpellInfo()->Id == SPELL_OVERLOADED_FLAME)
            targets.clear();
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_runemaster_glyph_payload::PreparePayload);
        AfterHit += SpellHitFn(spell_ascension_runemaster_glyph_payload::AfterPayloadHit);
        if (m_scriptSpellId == SPELL_UNLEASHED_FROST)
        {
            OnEffectLaunch += SpellEffectFn(spell_ascension_runemaster_glyph_payload::PreventFrostRoot,
                EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
            OnEffectLaunchTarget += SpellEffectFn(spell_ascension_runemaster_glyph_payload::PreventFrostRoot,
                EFFECT_1, SPELL_EFFECT_TRIGGER_SPELL);
        }
        if (m_scriptSpellId == SPELL_OVERLOADED_FLAME)
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
                spell_ascension_runemaster_glyph_payload::PreventRepeatedFlameChains, EFFECT_0, TARGET_UNIT_TARGET_ENEMY);
    }

    bool _overloaded = false;
};

class spell_ascension_runemaster_overloaded_frost : public AuraScript
{
    PrepareAuraScript(spell_ascension_runemaster_overloaded_frost);

    bool Validate(SpellInfo const* info) override
    {
        return info && info->Id == SPELL_OVERLOADED_FROST &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_ROOT) && ValidateSpellInfo({SPELL_OVERLOADED_CHILL});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void AfterRootExpires(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        if (Unit* caster = GetCaster())
            caster->CastSpell(GetTarget(), SPELL_OVERLOADED_CHILL, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_runemaster_overloaded_frost::AfterRootExpires,
            EFFECT_0, SPELL_AURA_MOD_ROOT, AURA_EFFECT_HANDLE_REAL);
    }
};
}

void ApplyAscensionRunemasterGlyphContracts(SpellInfo* info)
{
    if (info && info->Id == SPELL_UNLEASHED_ARCANE &&
        info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 &&
        info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
        info->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_TARGET_ENEMY &&
        info->Effects[EFFECT_0].TargetB.GetTarget() == TARGET_UNIT_DEST_AREA_ENEMY)
        info->AttributesEx2 |= SPELL_ATTR2_ALLOW_DEAD_TARGET;

    if (info && info->Id == SPELL_ARCANE_GLYPH_PASSIVE &&
        info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6)
    {
        SpellEffectInfo& legacyDamage = info->Effects[EFFECT_0];
        SpellEffectInfo& legacyCrit = info->Effects[EFFECT_1];
        if (legacyDamage.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && legacyDamage.MiscValue == SPELLMOD_DAMAGE &&
            legacyDamage.BasePoints == 4 && legacyDamage.DieSides == 1 &&
            legacyDamage.SpellClassMask == flag96(0, 8, 0) &&
            legacyCrit.IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) && legacyCrit.MiscValue == SPELLMOD_CRITICAL_CHANCE &&
            legacyCrit.BasePoints == 2 && legacyCrit.DieSides == 1 && !legacyCrit.SpellClassMask)
        {
            legacyDamage.ApplyAuraName = SPELL_AURA_DUMMY;
            legacyCrit.ApplyAuraName = SPELL_AURA_DUMMY;
        }
    }

    if (info && info->Id == SPELL_OVERLOADED_CHILL && info->SpellFamilyName == uint32(CLASS_SPIRIT_MAGE) + 6 &&
        info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DECREASE_SPEED) &&
        info->Effects[EFFECT_0].BasePoints == -51 && info->Effects[EFFECT_0].DieSides == 1 &&
        info->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER &&
        !info->Effects[EFFECT_0].TargetB.GetTarget() &&
        !info->Effects[EFFECT_1].Effect && !info->Effects[EFFECT_2].Effect)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        info->_InitializeExplicitTargetMask();
    }
}

void AddAscensionRunemasterGlyphScripts()
{
    RegisterSpellScript(spell_ascension_runemaster_glyph_cast);
    RegisterSpellScript(spell_ascension_runemaster_runic_obliteration_glyph);
    RegisterSpellScript(spell_ascension_runemaster_glyph_payload);
    RegisterSpellScript(spell_ascension_runemaster_overloaded_frost);
}
