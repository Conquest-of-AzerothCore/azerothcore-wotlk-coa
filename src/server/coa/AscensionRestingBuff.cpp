/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"

namespace
{
constexpr uint32 SPELL_REST = 818011;

bool IsFoodOrDrink(SpellInfo const* info)
{
    if (!info || info->Id == SPELL_REST)
        return false;

    switch (info->GetSpellSpecific())
    {
        case SPELL_SPECIFIC_FOOD:
        case SPELL_SPECIFIC_DRINK:
        case SPELL_SPECIFIC_FOOD_AND_DRINK:
            return true;
        default:
            return false;
    }
}

class rest_while_eating : public UnitScript
{
public:
    rest_while_eating() : UnitScript("rest_while_eating", true, {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || !aura || !IsFoodOrDrink(aura->GetSpellInfo()) || player->HasAura(SPELL_REST))
            return;

        player->CastSpell(player, SPELL_REST, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || !application || !IsFoodOrDrink(application->GetBase()->GetSpellInfo()))
            return;

        for (auto const& [id, other] : player->GetAppliedAuras())
            if (other != application && IsFoodOrDrink(other->GetBase()->GetSpellInfo()))
                return;

        player->RemoveAurasDueToSpell(SPELL_REST);
    }
};
}

void AddSC_AscensionRestingBuff()
{
    new rest_while_eating();
}
