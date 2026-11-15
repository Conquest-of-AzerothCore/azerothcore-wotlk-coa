/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTankStances.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"

namespace
{
    constexpr uint32 SPELL_TANK_STANCE_CRIT_REDUCTION = 991293;
    constexpr uint32 SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA = 807726;
    constexpr uint32 SPELL_VENOMANCER_EXPOSED_FLESH = 92144;
    constexpr uint32 SPELL_VENOMANCER_EXPOSED_FLESH_HELPER = 805098;

    bool IsResyncTrigger(uint32 spellId)
    {
        return Ascension::IsTankStanceAura(spellId) || spellId == SPELL_VENOMANCER_EXPOSED_FLESH ||
            spellId == SPELL_VENOMANCER_EXPOSED_FLESH_HELPER;
    }

    bool HasFortitudeBeetleForm(Player const* player)
    {
        return player->HasAura(SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA) &&
            (player->HasAura(SPELL_VENOMANCER_EXPOSED_FLESH) || player->HasSpell(SPELL_VENOMANCER_EXPOSED_FLESH));
    }

    bool HoldsCritReductionStance(Player const* player)
    {
        for (uint32 spellId = Ascension::FIRST_TANK_STANCE_AURA; spellId <= Ascension::LAST_TANK_STANCE_AURA; ++spellId)
            if (spellId != SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA && player->HasAura(spellId))
                return true;
        return HasFortitudeBeetleForm(player);
    }

    void SyncCritReduction(Player* player)
    {
        bool const wanted = HoldsCritReductionStance(player);
        bool const present = player->HasAura(SPELL_TANK_STANCE_CRIT_REDUCTION);
        if (wanted && !present)
            player->AddAura(SPELL_TANK_STANCE_CRIT_REDUCTION, player);
        else if (!wanted && present)
            player->RemoveAurasDueToSpell(SPELL_TANK_STANCE_CRIT_REDUCTION);
    }
}

class ascension_tank_stance_crit_reduction : public UnitScript
{
public:
    ascension_tank_stance_crit_reduction() : UnitScript("ascension_tank_stance_crit_reduction", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (Player* player = unit ? unit->ToPlayer() : nullptr; player && aura && IsResyncTrigger(aura->GetId()))
            SyncCritReduction(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (Player* player = unit ? unit->ToPlayer() : nullptr;
            player && application && IsResyncTrigger(application->GetBase()->GetId()))
            SyncCritReduction(player);
    }
};

void AddSC_AscensionTankStanceCritReduction()
{
    new ascension_tank_stance_crit_reduction();
}
