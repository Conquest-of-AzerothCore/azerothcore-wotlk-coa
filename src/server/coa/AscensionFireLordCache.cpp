/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCacheRewards.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "WorldScript.h"
#include <array>
#include <mutex>
#include <utility>
#include <vector>

namespace
{
constexpr uint32 FireLordCacheEntry = 2400040;
constexpr uint32 MoltenCoreMapId = 409;
constexpr uint8 RaidDifficultyCount = 4;

std::mutex g_poolLock;
std::array<std::vector<uint32>, RaidDifficultyCount> g_pools;

void LoadFireLordCachePool()
{
    std::array<std::vector<uint32>, RaidDifficultyCount> pools;
    if (QueryResult result = WorldDatabase.Query(
            "SELECT `RaidDifficulty`, `ItemEntry` FROM `coa_mc_fire_lord_cache_pool`"))
    {
        do
        {
            Field* fields = result->Fetch();
            uint8 tier = fields[0].Get<uint8>();
            if (tier < RaidDifficultyCount)
                pools[tier].push_back(fields[1].Get<uint32>());
        } while (result->NextRow());
    }
    else
    {
        LOG_WARN("coa",
            "coa_mc_fire_lord_cache_pool is missing: Cache of the Fire Lord will not open.");
    }

    std::lock_guard<std::mutex> guard(g_poolLock);
    g_pools = std::move(pools);
}

bool PickReward(uint8 tier, uint32& itemId)
{
    std::lock_guard<std::mutex> guard(g_poolLock);
    if (tier >= RaidDifficultyCount || g_pools[tier].empty())
        return false;

    itemId = g_pools[tier][urand(0, uint32(g_pools[tier].size() - 1))];
    return true;
}

bool TryGetBoundTier(ObjectGuid::LowType itemGuid, uint8& tier)
{
    QueryResult result = CharacterDatabase.Query(
        "SELECT `RaidDifficulty` FROM `coa_mc_fire_lord_cache_tier` WHERE `ItemGuid` = {}", itemGuid);
    if (!result)
        return false;

    tier = result->Fetch()[0].Get<uint8>();
    return true;
}

void ClearBoundTier(ObjectGuid::LowType itemGuid)
{
    CharacterDatabase.Execute("DELETE FROM `coa_mc_fire_lord_cache_tier` WHERE `ItemGuid` = {}", itemGuid);
}

bool OpenFireLordCache(Player* player, Item* item)
{
    ObjectGuid::LowType const itemGuid = item->GetGUID().GetCounter();

    uint8 tier;
    if (!TryGetBoundTier(itemGuid, tier))
    {
        tier = uint8(player->GetRaidDifficulty());
        LOG_DEBUG("coa",
            "Cache of the Fire Lord {} opened by {} with no bound raid tier; falling back to the "
            "current raid difficulty setting ({})",
            itemGuid, player->GetGUID().ToString(), uint32(tier));
    }

    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    uint32 rewardItem;
    if (!PickReward(tier, rewardItem))
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "The cache holds nothing for this raid difficulty.");
        return true;
    }

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(rewardItem);
    std::vector<AscensionCacheRewards::Reward> rewards = {
        { rewardItem, uint16(proto ? proto->ItemLevel : 0), 0, 0 }
    };

    if (!AscensionCacheRewards::Deliver(player, rewards, item))
        return true;

    ClearBoundTier(itemGuid);
    return true;
}

class item_ascension_fire_lord_cache : public ItemScript
{
public:
    item_ascension_fire_lord_cache() : ItemScript("item_ascension_fire_lord_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (item->GetEntry() != FireLordCacheEntry)
            return false;
        return OpenFireLordCache(player, item);
    }
};

class ascension_fire_lord_cache_bind : public PlayerScript
{
public:
    ascension_fire_lord_cache_bind()
        : PlayerScript("ascension_fire_lord_cache_bind", { PLAYERHOOK_ON_STORE_NEW_ITEM }) { }

    void OnPlayerStoreNewItem(Player* player, Item* item, uint32) override
    {
        if (!item || item->GetEntry() != FireLordCacheEntry)
            return;

        Map* map = player->GetMap();
        if (!map || map->GetId() != MoltenCoreMapId)
            return;

        CharacterDatabase.Execute(
            "REPLACE INTO `coa_mc_fire_lord_cache_tier` (`ItemGuid`, `RaidDifficulty`) VALUES ({}, {})",
            item->GetGUID().GetCounter(), uint32(map->GetSpawnMode()));
    }
};

class ascension_fire_lord_cache_pool : public WorldScript
{
public:
    ascension_fire_lord_cache_pool()
        : WorldScript("ascension_fire_lord_cache_pool",
              { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override
    {
        LoadFireLordCachePool();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            LoadFireLordCachePool();
    }
};
}

void AddSC_AscensionFireLordCache()
{
    new item_ascension_fire_lord_cache();
    new ascension_fire_lord_cache_bind();
    new ascension_fire_lord_cache_pool();
}
