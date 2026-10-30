/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornPriest.h"
#include "AscensionWarcraftRebornRules.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 PENANCE_DAMAGE_R1 = 47758;
constexpr uint32 PENANCE_HEAL_R1 = 47757;
constexpr uint32 PRIEST_PRAYER_OF_MENDING = 0x20;
constexpr std::array<uint32, 3> DIVINE_PROVIDENCE = { 1147562, 1147564, 1147565 };

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

class spell_ascension_reborn_improved_mind_blast : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_improved_mind_blast);

    bool CheckProc(ProcEventInfo&)
    {
        return GetTarget()->GetShapeshiftForm() == FORM_SHADOW;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_improved_mind_blast::CheckProc);
    }
};
}
}

void ApplyAscensionWarcraftRebornPriestContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo || std::find(DIVINE_PROVIDENCE.begin(), DIVINE_PROVIDENCE.end(), spellInfo->Id) == DIVINE_PROVIDENCE.end())
        return;

    SpellEffectInfo& healing = spellInfo->Effects[EFFECT_0];
    if (healing.ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER && healing.MiscValue == SPELLMOD_DAMAGE)
        healing.SpellClassMask[1] |= PRIEST_PRAYER_OF_MENDING;
}

void AddAscensionWarcraftRebornPriestScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_penance);
    RegisterSpellScript(spell_ascension_reborn_improved_mind_blast);
}
