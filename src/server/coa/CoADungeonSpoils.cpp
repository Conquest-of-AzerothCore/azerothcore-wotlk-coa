/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCacheRewards.h"
#include "AscensionSpecLoot.h"
#include "Containers.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DungeonHealth.h"
#include "GlobalScript.h"
#include "Group.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QueryResult.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include <algorithm>
#include <limits>
#include <unordered_set>
#include <vector>

namespace
{
    constexpr uint32 MarkOfTriumph = 1414502;
    constexpr uint32 DungeonSpoils = 2021814;
    constexpr uint32 DungeonSpoilsHeroic = 1202039;
    constexpr uint32 DungeonSpoilsMythic = 1027965;
    constexpr uint32 SpoilsLevelWindow = 2;

    std::unordered_set<uint32> MarkBosses;

    bool IsHeroicOrMythicVanillaDungeon(Map const* map)
    {
        return map && map->IsNonRaidDungeon() && DungeonHealth::IsVanillaDungeon(map->GetId()) &&
            (map->GetSpawnMode() == 1 || map->GetSpawnMode() == 2);
    }

    bool PlayerCanWear(Player const* player, ItemTemplate const* item)
    {
        return player->CanUseItem(item) == EQUIP_ERR_OK &&
            (!item->GetSkill() || player->GetSkillValue(item->GetSkill()));
    }

    bool AlreadyDropped(Loot const& loot, LootStoreItem const* entry)
    {
        return std::any_of(loot.items.begin(), loot.items.end(), [entry](LootItem const& dropped)
        {
            return dropped.itemid == entry->itemid;
        });
    }

    uint32 SpoilsLevelCap(Player const* player, std::list<LootStoreItem*> const& entries)
    {
        uint32 lowestLevel = std::numeric_limits<uint32>::max();
        for (LootStoreItem const* entry : entries)
            if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid); item && !entry->reference)
                lowestLevel = std::min(lowestLevel, item->RequiredLevel);
        return std::max<uint32>(player->GetLevel(), lowestLevel);
    }

    std::vector<LootStoreItem*> SpoilsFor(Player const* player, std::list<LootStoreItem*> const& entries,
        Loot const& loot, bool levelScaled, bool wearableOnly)
    {
        std::vector<LootStoreItem*> spoils;
        uint32 const levelCap = levelScaled ? SpoilsLevelCap(player, entries) : 0;
        uint32 bestLevel = 0;
        for (LootStoreItem* entry : entries)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid);
            if (!item || entry->reference || AlreadyDropped(loot, entry) ||
                (levelScaled && item->RequiredLevel > levelCap) ||
                (wearableOnly && !PlayerCanWear(player, item)))
                continue;
            spoils.push_back(entry);
            bestLevel = std::max(bestLevel, item->RequiredLevel);
        }

        if (levelScaled)
            std::erase_if(spoils, [bestLevel](LootStoreItem const* entry)
            {
                return sObjectMgr->GetItemTemplate(entry->itemid)->RequiredLevel + SpoilsLevelWindow < bestLevel;
            });
        return AscensionSpecLoot::PreferSpecialization(player, spoils, [](LootStoreItem const* entry)
        {
            return sObjectMgr->GetItemTemplate(entry->itemid);
        });
    }

    bool InDungeonFinderGroup(Player const* player)
    {
        Group const* group = player->GetGroup();
        return group && group->isLFGGroup();
    }

    bool IsDungeonSpoils(Item const* item)
    {
        return item && item->GetTemplate()->HasFlag(ITEM_FLAG_HAS_LOOT) &&
            item->GetTemplate()->ScriptId == sObjectMgr->GetScriptId("item_coa_dungeon_spoils");
    }

    void OpenDungeonSpoils(Player* player, Item* item)
    {
        player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);
        if (!player->IsAlive() || player->IsInCombat())
            return;

        Loot loot;
        loot.containerGUID = item->GetGUID();
        loot.FillLoot(item->GetEntry(), LootTemplates_Item, player, true, true);

        std::vector<AscensionCacheRewards::Reward> rewards;
        for (uint32 slot = 0; slot < loot.GetMaxSlotInLootFor(player); ++slot)
        {
            LootItem const* reward = loot.LootItemInSlot(slot, player);
            if (!reward)
                continue;
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(reward->itemid);
            if (!proto)
                continue;
            rewards.push_back({ reward->itemid, uint16(proto->ItemLevel), 0, uint8(proto->SubClass),
                uint32(reward->count ? reward->count : 1), reward->randomPropertyId });
        }
        AscensionCacheRewards::Deliver(player, rewards, item);
    }
}

class item_coa_dungeon_spoils final : public ItemScript
{
public:
    item_coa_dungeon_spoils() : ItemScript("item_coa_dungeon_spoils") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (!IsDungeonSpoils(item))
            return false;
        OpenDungeonSpoils(player, item);
        return true;
    }
};

class CoADungeonSpoilsOpen final : public PlayerScript
{
public:
    CoADungeonSpoilsOpen() : PlayerScript("CoADungeonSpoilsOpen", { PLAYERHOOK_ON_BEFORE_OPEN_ITEM }) { }

    bool OnPlayerBeforeOpenItem(Player* player, Item* item) override
    {
        if (!IsDungeonSpoils(item))
            return true;
        ObjectGuid const spoils = item->GetGUID();
        OpenDungeonSpoils(player, item);
        player->SendLootRelease(spoils);
        return false;
    }
};

class CoADungeonSpoilsLevel final : public GlobalScript
{
public:
    CoADungeonSpoilsLevel() : GlobalScript("CoADungeonSpoilsLevel", { GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED }) { }

    bool OnBeforeLootEqualChanced(Player const* player, std::list<LootStoreItem*> entries, Loot& loot,
        LootStore const& store) override
    {
        if (!player || &store != &LootTemplates_Item)
            return true;
        Item const* container = player->GetItemByGuid(loot.containerGUID);
        if (!container || !IsSpoilsBag(container->GetEntry()))
            return true;

        bool const levelScaled = container->GetEntry() == DungeonSpoils;
        std::vector<LootStoreItem*> spoils = SpoilsFor(player, entries, loot, levelScaled, true);
        if (spoils.empty())
            spoils = SpoilsFor(player, entries, loot, levelScaled, false);
        if (!spoils.empty())
            loot.AddItem(*Acore::Containers::SelectRandomContainerElement(spoils));
        return false;
    }

private:
    static bool IsSpoilsBag(uint32 entry)
    {
        return entry == DungeonSpoils || entry == DungeonSpoilsHeroic || entry == DungeonSpoilsMythic;
    }
};

class CoADungeonFinalBossReward final : public GlobalScript
{
public:
    CoADungeonFinalBossReward()
        : GlobalScript("CoADungeonFinalBossReward", { GLOBALHOOK_ON_AFTER_UPDATE_ENCOUNTER_STATE }) { }

    void OnAfterUpdateEncounterState(Map* map, EncounterCreditType, uint32, Unit*, Difficulty,
        std::list<DungeonEncounter const*> const*, uint32 dungeonCompleted, bool) override
    {
        if (!dungeonCompleted || !map || !map->IsNonRaidDungeon() || !DungeonHealth::IsVanillaDungeon(map->GetId()))
            return;
        uint32 const reward = FinalBossReward(map->GetSpawnMode());
        if (!reward)
            return;
        map->DoForAllPlayers([reward](Player* player)
        {
            if (reward != DungeonSpoils || !InDungeonFinderGroup(player))
                player->AddItem(reward, 1);
        });
    }

private:
    static uint32 FinalBossReward(uint8 spawnMode)
    {
        switch (spawnMode)
        {
            case 0:
                return DungeonSpoils;
            case 1:
            case 2:
                return MarkOfTriumph;
            default:
                return 0;
        }
    }
};

class CoADungeonBossMarkLoad final : public WorldScript
{
public:
    CoADungeonBossMarkLoad() : WorldScript("CoADungeonBossMarkLoad", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        MarkBosses.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry FROM coa_dungeon_mark_bosses"))
        {
            do
            {
                MarkBosses.insert(result->Fetch()[0].Get<uint32>());
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA dungeon bosses that give a Mark of Triumph on Heroic and Mythic", MarkBosses.size());
    }
};

class CoADungeonBossMark final : public UnitScript
{
public:
    CoADungeonBossMark() : UnitScript("CoADungeonBossMark", true, { UNITHOOK_ON_UNIT_DEATH }) { }

    void OnUnitDeath(Unit* unit, Unit*) override
    {
        Creature const* boss = unit ? unit->ToCreature() : nullptr;
        if (!boss || !MarkBosses.count(boss->GetEntry()) || !IsHeroicOrMythicVanillaDungeon(boss->GetMap()))
            return;
        boss->GetMap()->DoForAllPlayers([](Player* player)
        {
            player->AddItem(MarkOfTriumph, 1);
        });
    }
};

void AddSC_CoADungeonSpoils()
{
    new item_coa_dungeon_spoils();
    new CoADungeonSpoilsOpen();
    new CoADungeonSpoilsLevel();
    new CoADungeonFinalBossReward();
    new CoADungeonBossMarkLoad();
    new CoADungeonBossMark();
}
