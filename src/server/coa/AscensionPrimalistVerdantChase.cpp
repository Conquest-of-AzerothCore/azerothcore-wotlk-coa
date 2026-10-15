/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "SpellScript.h"

#include <algorithm>
#include <utility>
#include <vector>

namespace
{
enum VerdantChaseSpells : uint32
{
    VerdantChaseHelper = 560306,
    SpiritCharge = 800144,
    PrimalRush = 500696
};

class spell_ascension_verdant_chase : public SpellScript
{
    PrepareSpellScript(spell_ascension_verdant_chase);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == VerdantChaseHelper && ValidateSpellInfo({SpiritCharge, PrimalRush});
    }

    void Reduce(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster()->ToPlayer();
        uint32 first = index == EFFECT_0 ? SpiritCharge : PrimalRush;
        std::vector<std::pair<uint32, uint32>> reductions;
        for (auto const& entry : player->GetSpellCooldownMap())
            if (sSpellMgr->GetFirstSpellInChain(entry.first) == first)
                reductions.emplace_back(entry.first, CalculatePct(player->GetSpellCooldownDelay(entry.first),
                    std::clamp(GetEffectValue(), 0, 100)));
        for (auto const& [spell, reduction] : reductions)
            if (reduction)
                player->ModifySpellCooldown(spell, -int32(reduction));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_verdant_chase::Reduce, EFFECT_0, SPELL_EFFECT_ANY);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_verdant_chase::Reduce, EFFECT_1, SPELL_EFFECT_ANY);
    }
};
}

void AddSC_AscensionPrimalistVerdantChase()
{
    RegisterSpellScript(spell_ascension_verdant_chase);
}
