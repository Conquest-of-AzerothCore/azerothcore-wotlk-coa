/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include <algorithm>
#include <set>

namespace
{
enum RunemasterTalentEffectSpells : uint32
{
    SPELL_EARTH_WIND_AND_FIRE = 706531,
    SPELL_WILD_STEAM = 803737,
    SPELL_FRACTURE = 803018,
    SPELL_HARNESSED_LEYLINES = 804316
};

constexpr std::size_t WILD_STEAM_STRUCK_ENEMIES = 5;
constexpr float FRACTURE_MANA_BURN_ATTACK_POWER = 0.35f;
constexpr int32 HARNESSED_LEYLINES_DURATION = 15000;
constexpr uint8 HARNESSED_LEYLINES_STACKS = 10;

bool IsRunemaster(Unit const* unit)
{
    return unit && unit->IsPlayer() && unit->getClass() == CLASS_SPIRIT_MAGE;
}

class spell_ascension_runemaster_earth_wind_and_fire : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_earth_wind_and_fire);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_EARTH_WIND_AND_FIRE, SPELL_WILD_STEAM});
    }

    bool Load() override
    {
        return IsRunemaster(GetCaster());
    }

    void CountStruckEnemy()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || target == caster || caster->IsFriendlyTo(target) || !_struck.insert(target->GetGUID()).second)
            return;
        if (_struck.size() == WILD_STEAM_STRUCK_ENEMIES && caster->IsAlive() &&
            caster->HasAura(SPELL_EARTH_WIND_AND_FIRE, caster->GetGUID()))
            caster->CastSpell(caster, SPELL_WILD_STEAM, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_runemaster_earth_wind_and_fire::CountStruckEnemy);
    }

    std::set<ObjectGuid> _struck;
};

class spell_ascension_runemaster_harnessed_leylines : public SpellScript
{
    PrepareSpellScript(spell_ascension_runemaster_harnessed_leylines);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_HARNESSED_LEYLINES && info->SpellFamilyName == 38 &&
            info->GetDuration() == HARNESSED_LEYLINES_DURATION && info->StackAmount == HARNESSED_LEYLINES_STACKS &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_DAMAGE;
    }

    bool Load() override { return IsRunemaster(GetCaster()); }

    void SnapshotDuration()
    {
        Unit* caster = GetCaster();
        if (Aura* aura = caster->GetAura(SPELL_HARNESSED_LEYLINES, caster->GetGUID()))
        {
            _remainingDuration = aura->GetDuration();
            if (!_remainingDuration)
                caster->RemoveAurasDueToSpell(SPELL_HARNESSED_LEYLINES, caster->GetGUID());
        }
    }

    void RestoreDuration()
    {
        Aura* aura = GetHitAura();
        if (_remainingDuration > 0 && GetHitUnit() == GetCaster() && aura &&
            aura->GetCasterGUID() == GetCaster()->GetGUID())
            aura->SetDuration(_remainingDuration);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_runemaster_harnessed_leylines::SnapshotDuration);
        AfterHit += SpellHitFn(spell_ascension_runemaster_harnessed_leylines::RestoreDuration);
    }

    int32 _remainingDuration = 0;
};

class runemaster_fracture_mana_burn : public UnitScript
{
public:
    runemaster_fracture_mana_burn() : UnitScript("runemaster_fracture_mana_burn", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (info->Id != SPELL_FRACTURE || index != EFFECT_2 || !IsRunemaster(caster) ||
            info->Effects[EFFECT_2].Effect != SPELL_EFFECT_POWER_BURN)
            return;
        value += std::max(0.0f, caster->GetTotalAttackPowerValue(BASE_ATTACK)) * FRACTURE_MANA_BURN_ATTACK_POWER;
    }
};

class runemaster_fracture_frozen_critical : public AllSpellScript
{
public:
    runemaster_fracture_frozen_critical() : AllSpellScript("runemaster_fracture_frozen_critical",
        {ALLSPELLHOOK_ON_CALCULATED_TARGET}) { }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        Unit* caster = spell->GetCaster();
        if (info->Id != SPELL_FRACTURE || !target || !IsRunemaster(caster) || hit.missCondition != SPELL_MISS_NONE ||
            !info->IsCritCapable() || info->HasAttribute(SPELL_ATTR2_CANT_CRIT) ||
            !target->HasAuraState(AURA_STATE_FROZEN, info, caster))
            return;
        hit.crit = true;
    }
};
}

void AddSC_AscensionRunemasterTalentEffects()
{
    RegisterSpellScript(spell_ascension_runemaster_earth_wind_and_fire);
    RegisterSpellScript(spell_ascension_runemaster_harnessed_leylines);
    new runemaster_fracture_mana_burn();
    new runemaster_fracture_frozen_critical();
}
