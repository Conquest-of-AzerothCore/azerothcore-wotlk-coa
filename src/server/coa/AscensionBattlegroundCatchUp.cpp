/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundBrackets.h"
#include "AscensionBattlegroundBracketsPolicy.h"
#include "Battleground.h"
#include "Config.h"
#include "DataMap.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"

namespace
{
namespace Policy = AscensionBattlegroundBracketsPolicy;

constexpr char LiftKey[] = "AscensionBattlegroundCatchUp.Lift";

struct AppliedLift final : DataMap::Base
{
    Policy::Lift lift;
};

void HandleLiftModifiers(Unit* unit, Policy::Lift const& lift, bool apply)
{
    for (std::size_t stat = 0; stat < lift.stats.size(); ++stat)
        if (lift.stats[stat] != 0.0f)
            unit->HandleStatFlatModifier(UnitMods(UNIT_MOD_STAT_START + stat), BASE_VALUE, lift.stats[stat], apply);

    if (lift.health != 0.0f)
        unit->HandleStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, lift.health, apply);

    if (lift.mana != 0.0f)
        unit->HandleStatFlatModifier(UNIT_MOD_MANA, BASE_VALUE, lift.mana, apply);
}

void RemoveLift(Unit* unit)
{
    AppliedLift const* applied = unit->CustomData.Get<AppliedLift>(LiftKey);
    if (!applied)
        return;

    Policy::Lift const lift = applied->lift;
    unit->CustomData.Erase(LiftKey);
    HandleLiftModifiers(unit, lift, false);
}

void ApplyLift(Unit* unit, Policy::Lift const& lift)
{
    RemoveLift(unit);
    if (lift.Empty())
        return;

    HandleLiftModifiers(unit, lift, true);
    auto* applied = new AppliedLift();
    applied->lift = lift;
    unit->CustomData.Set(LiftKey, applied);
}

uint32 LiftTargetLevel(Player const* player)
{
    Map const* map = player->FindMap();
    if (!map || !map->IsBattleground())
        return 0;

    Battleground const* battleground = player->GetBattleground();
    if (!battleground || battleground->isArena() || battleground->GetMapId() != map->GetId())
        return 0;

    return AscensionBattlegroundBrackets::WidenedMaxLevel(battleground->GetMapId(), battleground->GetBracketId());
}

Policy::LevelValues PlayerLevelValues(Player const* player, uint8 level)
{
    PlayerClassLevelInfo classInfo;
    sObjectMgr->GetPlayerClassLevelInfo(player->getClass(), level, &classInfo);

    PlayerLevelInfo levelInfo;
    sObjectMgr->GetPlayerLevelInfo(player->getRace(true), player->getClass(), level, &levelInfo);

    Policy::LevelValues values{ classInfo.basehealth, classInfo.basemana, {} };
    for (uint8 stat = STAT_STRENGTH; stat < MAX_STATS; ++stat)
        values.stats[stat] = levelInfo.stats[stat];
    return values;
}

void RefreshPlayerLift(Player* player)
{
    uint32 const target = LiftTargetLevel(player);
    uint8 const level = player->GetLevel();
    if (target <= level)
    {
        RemoveLift(player);
        return;
    }

    ApplyLift(player, Policy::LiftBetween(PlayerLevelValues(player, level), PlayerLevelValues(player, uint8(target))));
}

class ascension_battleground_wide_brackets_config : public WorldScript
{
public:
    ascension_battleground_wide_brackets_config()
        : WorldScript("ascension_battleground_wide_brackets_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            return;

        AscensionBattlegroundBrackets::Configure(
            sConfigMgr->GetOption<bool>("CoA.Battleground.WideBrackets.Enable", true),
            sConfigMgr->GetOption<std::string>("CoA.Battleground.WideBrackets.Ranges", "10-29,30-49,50-59"));
    }
};

class ascension_battleground_catch_up_battleground : public AllBattlegroundScript
{
public:
    ascension_battleground_catch_up_battleground()
        : AllBattlegroundScript("ascension_battleground_catch_up_battleground",
            {ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_ADD_PLAYER, ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_REMOVE_PLAYER_AT_LEAVE})
    { }

    void OnBattlegroundAddPlayer(Battleground* /*battleground*/, Player* player) override
    {
        RefreshPlayerLift(player);
    }

    void OnBattlegroundRemovePlayerAtLeave(Battleground* /*battleground*/, Player* player) override
    {
        RemoveLift(player);
    }
};

class ascension_battleground_catch_up_player : public PlayerScript
{
public:
    ascension_battleground_catch_up_player()
        : PlayerScript("ascension_battleground_catch_up_player",
            {PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_MAP_CHANGED, PLAYERHOOK_ON_LOGOUT})
    { }

    void OnPlayerLevelChanged(Player* player, uint8 /*oldLevel*/) override
    {
        if (player->CustomData.Get<AppliedLift>(LiftKey))
            RefreshPlayerLift(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        RefreshPlayerLift(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        RemoveLift(player);
    }
};
}

void AddSC_AscensionBattlegroundCatchUp()
{
    new ascension_battleground_wide_brackets_config();
    new ascension_battleground_catch_up_battleground();
    new ascension_battleground_catch_up_player();
}
