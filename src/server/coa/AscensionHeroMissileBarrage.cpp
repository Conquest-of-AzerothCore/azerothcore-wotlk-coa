/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
enum MissileBarrageSpells : uint32
{
    ArcaneMissilesRank1 = 5143
};

class aura_hero_missile_barrage : public AuraScript
{
    PrepareAuraScript(aura_hero_missile_barrage);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ArcaneMissilesRank1});
    }

    static SpellInfo const* HighestKnownArcaneMissiles(Player const* player)
    {
        SpellInfo const* known = nullptr;
        for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(ArcaneMissilesRank1); rank; rank = rank->GetNextRankSpell())
            if (player->HasSpell(rank->Id))
                known = rank;
        return known;
    }

    void CalculateChannelReduction(AuraEffect const*, int32& amount, bool&)
    {
        Player const* player = GetUnitOwner() ? GetUnitOwner()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_HERO)
            return;

        if (SpellInfo const* missiles = HighestKnownArcaneMissiles(player))
            amount = std::max(amount, -missiles->GetDuration() / 2);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_hero_missile_barrage::CalculateChannelReduction, EFFECT_0,
            SPELL_AURA_ADD_FLAT_MODIFIER);
    }
};
}

void AddSC_AscensionHeroMissileBarrage()
{
    RegisterSpellScript(aura_hero_missile_barrage);
}
