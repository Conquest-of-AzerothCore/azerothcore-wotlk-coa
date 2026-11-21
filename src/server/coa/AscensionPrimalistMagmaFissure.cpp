/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Creature.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"
#include <cmath>

namespace
{
constexpr uint32 MagmaFissureInstantCast = 803299;

bool IsMagmaFissure(SpellInfo const* info)
{
    switch (info->Id)
    {
        case 802793:
        case 803826:
        case 803827:
        case 803828:
        case 803829:
            return info->SpellFamilyName == 37;
        default:
            return false;
    }
}

class primalist_magma_fissure_metadata : public GlobalScript
{
public:
    primalist_magma_fissure_metadata() : GlobalScript("primalist_magma_fissure_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (IsMagmaFissure(info))
            info->AscensionIgnoreAbsorb = true;
    }
};

class primalist_magma_fissure_instant_cast : public AllSpellScript
{
public:
    primalist_magma_fissure_instant_cast() : AllSpellScript("primalist_magma_fissure_instant_cast",
        {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* spellInfo, bool) override
    {
        if (!caster || !caster->IsPlayer() || spell->IsTriggered())
            return;

        if (IsMagmaFissure(spellInfo))
        {
            caster->CastSpell(caster, MagmaFissureInstantCast, true);
            return;
        }

        if (AuraEffect const* instantCast = caster->GetAuraEffect(MagmaFissureInstantCast, EFFECT_0))
            if (instantCast->IsAffectedOnSpell(spellInfo))
                caster->RemoveAurasDueToSpell(MagmaFissureInstantCast);
    }
};

bool CanBeKnockedBack(Unit* target)
{
    if ((target->IsVehicle() && target->GetCreatureType() != CREATURE_TYPE_BEAST) || target->GetVehicle() ||
        target->HasUnitState(UNIT_STATE_ROOT))
        return false;

    Creature* creature = target->ToCreature();
    return !creature || (!creature->isWorldBoss() && !creature->IsDungeonBoss() && !creature->IsImmuneToKnockback() &&
        creature->GetCreatureType() != CREATURE_TYPE_GIANT);
}

class spell_primalist_magma_fissure_knockback : public SpellScript
{
    PrepareSpellScript(spell_primalist_magma_fissure_knockback);

    void HandleKnockback(SpellEffIndex effIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!caster || !target || target == caster || !CanBeKnockedBack(target))
            return;

        float const facing = caster->GetOrientation();
        float const alongX = std::cos(facing);
        float const alongY = std::sin(facing);
        float const offsetX = target->GetPositionX() - caster->GetPositionX();
        float const offsetY = target->GetPositionY() - caster->GetPositionY();
        float const along = offsetX * alongX + offsetY * alongY;
        float const towardsLeft = offsetY * alongX - offsetX * alongY;
        float fromX = caster->GetPositionX() + along * alongX;
        float fromY = caster->GetPositionY() + along * alongY;

        if (std::fabs(towardsLeft) < 0.1f)
        {
            float const side = towardsLeft > 0.0f ? 1.0f : -1.0f;
            fromX = target->GetPositionX() + side * alongY;
            fromY = target->GetPositionY() - side * alongX;
        }

        SpellEffectInfo const& effect = GetSpellInfo()->Effects[effIndex];
        target->KnockbackFrom(fromX, fromY, float(effect.MiscValue), float(effect.MiscValueB));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_primalist_magma_fissure_knockback::HandleKnockback, EFFECT_1,
            SPELL_EFFECT_SCRIPT_EFFECT);
    }
};
}

void AddSC_AscensionPrimalistMagmaFissure()
{
    RegisterSpellScript(spell_primalist_magma_fissure_knockback);
    new primalist_magma_fissure_metadata();
    new primalist_magma_fissure_instant_cast();
}
