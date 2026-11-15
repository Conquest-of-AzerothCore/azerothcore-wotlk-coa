/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTankStances.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include <algorithm>
#include <array>

namespace
{
    constexpr uint32 SPELL_TANK_STANCE_CRIT_REDUCTION = Ascension::TANK_STANCE_CRIT_REDUCTION_AURA;
    constexpr uint32 SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA = 807726;
    constexpr uint32 SPELL_VENOMANCER_EXPOSED_FLESH = 92144;
    constexpr uint32 SPELL_VENOMANCER_EXPOSED_FLESH_HELPER = 805098;

    struct StockTankStance
    {
        uint8 classId;
        uint32 spellId;
    };

    constexpr std::array<StockTankStance, 6> STOCK_TANK_STANCES = {{
        {CLASS_WARRIOR, 71}, {CLASS_WARRIOR, 1100071},
        {CLASS_DRUID, 5487}, {CLASS_DRUID, 1105487}, {CLASS_DRUID, 9634}, {CLASS_DRUID, 1109634},
    }};

    bool IsStockTankStanceAura(uint32 spellId)
    {
        return std::ranges::any_of(STOCK_TANK_STANCES,
            [spellId](StockTankStance const& stance) { return stance.spellId == spellId; });
    }

    bool HoldsStockTankStance(Player const* player)
    {
        uint8 const classId = player->getClass();
        return std::ranges::any_of(STOCK_TANK_STANCES, [player, classId](StockTankStance const& stance)
            { return stance.classId == classId && player->HasAura(stance.spellId); });
    }

    bool IsResyncTrigger(uint32 spellId)
    {
        return Ascension::IsTankStanceAura(spellId) || IsStockTankStanceAura(spellId) ||
            spellId == SPELL_VENOMANCER_EXPOSED_FLESH || spellId == SPELL_VENOMANCER_EXPOSED_FLESH_HELPER;
    }

    bool HasFortitudeBeetleForm(Player const* player)
    {
        return player->HasAura(SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA) &&
            (player->HasAura(SPELL_VENOMANCER_EXPOSED_FLESH) || player->HasSpell(SPELL_VENOMANCER_EXPOSED_FLESH));
    }

    bool HoldsCritReductionStance(Player const* player)
    {
        for (auto const& [spellId, application] : player->GetAppliedAuras())
            if (spellId != SPELL_VENOMANCER_BEETLE_FORM_TANK_AURA && Ascension::IsTankStanceAura(spellId))
                return true;
        return HasFortitudeBeetleForm(player) || HoldsStockTankStance(player);
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
