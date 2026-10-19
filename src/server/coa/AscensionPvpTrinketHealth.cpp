/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"

namespace
{
struct TrinketHealth
{
    uint32 Equip;
    uint32 Health;
};

constexpr TrinketHealth TRINKETS[] = {
    { 26830, 26832 },
    { 26831, 26833 },
};

void Refresh(Player* player, TrinketHealth const& trinket)
{
    bool const wanted = player->HasAura(trinket.Equip) && player->FindMap() &&
        player->GetMap()->IsBattlegroundOrArena();
    if (wanted == player->HasAura(trinket.Health))
        return;

    if (wanted)
        player->CastSpell(player, trinket.Health, true);
    else
        player->RemoveAurasDueToSpell(trinket.Health);
}

TrinketHealth const* FindByEquip(uint32 spellId)
{
    for (TrinketHealth const& trinket : TRINKETS)
        if (trinket.Equip == spellId)
            return &trinket;
    return nullptr;
}

class pvp_trinket_health_aura : public UnitScript
{
public:
    pvp_trinket_health_aura() : UnitScript("pvp_trinket_health_aura", true, {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (TrinketHealth const* trinket = player && aura ? FindByEquip(aura->GetId()) : nullptr)
            Refresh(player, *trinket);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (TrinketHealth const* trinket = player && application ? FindByEquip(application->GetBase()->GetId()) : nullptr)
            Refresh(player, *trinket);
    }
};

class pvp_trinket_health_map : public PlayerScript
{
public:
    pvp_trinket_health_map() : PlayerScript("pvp_trinket_health_map", {PLAYERHOOK_ON_MAP_CHANGED}) { }

    void OnPlayerMapChanged(Player* player) override
    {
        for (TrinketHealth const& trinket : TRINKETS)
            Refresh(player, trinket);
    }
};
}

void AddSC_AscensionPvpTrinketHealth()
{
    new pvp_trinket_health_aura();
    new pvp_trinket_health_map();
}
