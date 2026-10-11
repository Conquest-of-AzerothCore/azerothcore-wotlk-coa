/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornRules.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 PENANCE_DAMAGE_R1 = 47758;
constexpr uint32 PENANCE_HEAL_R1 = 47757;

uint32 RebornRank(uint32 stockFirstRank, uint8 rank)
{
    uint32 const stock = sSpellMgr->GetSpellWithRank(stockFirstRank, rank, false);
    return RebornSpell(stock, [](std::uint32_t spellId) { return sSpellMgr->GetSpellInfo(spellId) != nullptr; });
}

class spell_ascension_reborn_penance : public SpellScript
{
    PrepareSpellScript(spell_ascension_reborn_penance);

    bool Load() override
    {
        return GetCaster()->IsPlayer();
    }

    SpellCastResult CheckCast()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        if (!target)
            return SPELL_FAILED_BAD_TARGETS;
        if (!caster->IsFriendlyTo(target))
        {
            if (!caster->IsValidAttackTarget(target))
                return SPELL_FAILED_BAD_TARGETS;
            if (!caster->isInFront(target))
                return SPELL_FAILED_UNIT_NOT_INFRONT;
        }
        return SPELL_CAST_OK;
    }

    void HandleDummy(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || !target->IsAlive())
            return;
        uint8 const rank = GetSpellInfo()->GetRank();
        uint32 const channel = RebornRank(caster->IsFriendlyTo(target) ? PENANCE_HEAL_R1 : PENANCE_DAMAGE_R1, rank);
        if (channel)
            caster->CastSpell(target, channel, false);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_reborn_penance::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reborn_penance::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}
}

void AddAscensionWarcraftRebornPriestScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_penance);
}
