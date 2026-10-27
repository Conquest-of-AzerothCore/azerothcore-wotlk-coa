/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CellImpl.h"
#include "Containers.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
enum FrostSpreeSpells : uint32
{
    FrostBlitz = 913454
};

constexpr float FrostSpreeRange = 10.0f;

Unit* SelectFrostSpreeTarget(Unit* caster)
{
    std::list<Unit*> targets;
    Acore::AnyUnfriendlyUnitInObjectRangeCheck check(caster, caster, FrostSpreeRange);
    Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(caster, targets, check);
    Cell::VisitObjects(caster, searcher, FrostSpreeRange);
    targets.remove_if([caster](Unit* target)
    {
        return target->HasStealthAura() || target->HasInvisibilityAura() ||
            !caster->IsValidAttackTarget(target) || !caster->IsWithinLOSInMap(target);
    });
    return targets.empty() ? nullptr : Acore::Containers::SelectRandomContainerElement(targets);
}

bool CanAssault(Unit* caster)
{
    return caster->IsAlive() && !caster->GetVehicleBase() &&
        !caster->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED);
}

void FrostSpreeAssault(Unit* caster, Unit* target)
{
    if (!CanAssault(caster))
        return;
    float x, y, z;
    caster->GetContactPoint(target, x, y, z);
    caster->NearTeleportTo(x, y, z, caster->GetAngle(target), true);
    caster->CastSpell(target, FrostBlitz, true);
}

class spell_ascension_wildcard_frost_spree_aura : public AuraScript
{
    PrepareAuraScript(spell_ascension_wildcard_frost_spree_aura);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({FrostBlitz});
    }

    void Tick(AuraEffect const*)
    {
        if (Unit* target = SelectFrostSpreeTarget(GetTarget()))
            FrostSpreeAssault(GetTarget(), target);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(
            spell_ascension_wildcard_frost_spree_aura::Tick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

class spell_ascension_wildcard_frost_spree : public SpellScript
{
    PrepareSpellScript(spell_ascension_wildcard_frost_spree);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({FrostBlitz});
    }

    void HandleDummy(SpellEffIndex)
    {
        if (Unit* target = GetHitUnit())
            FrostSpreeAssault(GetCaster(), target);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(
            spell_ascension_wildcard_frost_spree::HandleDummy, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionWildcardFrostSpree()
{
    RegisterSpellAndAuraScriptPair(spell_ascension_wildcard_frost_spree, spell_ascension_wildcard_frost_spree_aura);
}
