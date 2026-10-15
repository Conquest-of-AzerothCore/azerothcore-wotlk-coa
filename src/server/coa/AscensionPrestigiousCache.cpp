/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCacheRewards.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "World.h"
#include <algorithm>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 GenericCacheAll = 1287330;
constexpr uint32 GenericCacheTbc = 1297304;
constexpr uint32 GenericCacheWotlk = 1297305;

std::vector<uint32> const ClassicLadder = { 1287304, 1287305, 1287306, 1287307,
                                            1287308, 1287309, 1287310, 1287311 };
std::vector<uint32> const TbcLadder = { 1297310, 1297311, 1297312, 1297313, 1297314,
                                        1297315, 1297316, 1297317, 1297318 };

using CachePool = std::vector<AscensionCacheRewards::Reward>;

struct ContentToken
{
    uint32 itemId;
    uint8 stage;
};

std::mutex g_poolLock;
std::unordered_map<uint32, CachePool> g_pools;
std::unordered_map<uint32, std::vector<ContentToken>> g_tokens;

uint32 g_tokenChancePercent = 25;
uint32 g_secondTokenChancePercent = 5;
uint8 g_releasedTokenStage = 12;
uint8 g_classicStages = 8;
uint8 g_tbcStages = 0;

void LoadPrestigiousCachePools()
{
    g_tokenChancePercent = sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.TokenChancePercent", 25);
    g_secondTokenChancePercent = sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.SecondTokenChancePercent", 5);
    g_releasedTokenStage = uint8(std::min<uint32>(
        sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.ReleaseStage", 6) * 2, 12));
    g_classicStages = uint8(sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.ClassicStages", 8));
    g_tbcStages = uint8(sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.TbcStages", 0));

    std::unordered_map<uint32, CachePool> pools;
    if (QueryResult result = WorldDatabase.Query(
            "SELECT `CacheItemId`, `RewardItemId`, `RewardItemLevel`, `StatType`, `ArmorClass` "
            "FROM `ascension_prestigious_cache_reward`"))
    {
        do
        {
            Field* fields = result->Fetch();
            pools[fields[0].Get<uint32>()].push_back(
                { fields[1].Get<uint32>(), fields[2].Get<uint16>(), fields[3].Get<uint8>(),
                  fields[4].Get<uint8>() });
        } while (result->NextRow());
    }
    else
    {
        LOG_WARN("coa",
            "ascension_prestigious_cache_reward is missing: Prestigious Caches will not open.");
    }

    std::unordered_map<uint32, std::vector<ContentToken>> tokens;
    if (QueryResult result = WorldDatabase.Query("SELECT `CacheItemId`, `RewardItemId`, `TokenStage` "
                                                 "FROM `ascension_cache_content_token`"))
    {
        do
        {
            Field* fields = result->Fetch();
            tokens[fields[0].Get<uint32>()].push_back(
                { fields[1].Get<uint32>(), fields[2].Get<uint8>() });
        } while (result->NextRow());
    }
    else
    {
        LOG_WARN("coa",
            "ascension_cache_content_token is missing: Prestigious Caches pay no tier tokens.");
    }

    std::lock_guard<std::mutex> guard(g_poolLock);
    g_pools = std::move(pools);
    g_tokens = std::move(tokens);
}

CachePool const* GetPool(uint32 cacheItemId)
{
    std::lock_guard<std::mutex> guard(g_poolLock);
    auto it = g_pools.find(cacheItemId);
    return it == g_pools.end() ? nullptr : &it->second;
}

uint32 NewestReleasedTier(std::vector<uint32> const& ladder, uint8 released)
{
    uint32 resolved = 0;
    for (uint8 index = 0; index < ladder.size() && index < released; ++index)
    {
        CachePool const* pool = GetPool(ladder[index]);
        if (pool && !pool->empty())
            resolved = ladder[index];
    }
    return resolved;
}

uint32 NewestReleasedCache()
{
    if (g_tbcStages)
    {
        uint32 tier = NewestReleasedTier(TbcLadder, g_tbcStages);
        if (tier)
            return tier;
    }
    return NewestReleasedTier(ClassicLadder, g_classicStages);
}

uint8 PrimaryStat(Player const* player)
{
    uint32 strength = player->GetStat(STAT_STRENGTH);
    uint32 agility = player->GetStat(STAT_AGILITY);
    uint32 intellect = player->GetStat(STAT_INTELLECT);
    if (strength >= agility && strength >= intellect)
        return 1;
    return agility >= intellect ? 2 : 3;
}

bool PickReward(Player* player, CachePool const& pool, AscensionCacheRewards::Reward& out)
{
    std::vector<AscensionCacheRewards::Reward const*> preferred;
    std::vector<AscensionCacheRewards::Reward const*> fallback;
    uint8 stat = PrimaryStat(player);
    for (AscensionCacheRewards::Reward const& reward : pool)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(reward.itemId);
        if (!proto || player->CanUseItem(proto) != EQUIP_ERR_OK)
            continue;
        fallback.push_back(&reward);
        if (reward.statType == stat || reward.statType == 4 || reward.statType == 5)
            preferred.push_back(&reward);
    }

    std::vector<AscensionCacheRewards::Reward const*> const& candidates =
        preferred.empty() ? fallback : preferred;
    if (candidates.empty())
        return false;

    out = *candidates[urand(0, uint32(candidates.size() - 1))];
    return true;
}

bool PickToken(Player* player, uint32 cacheItemId, AscensionCacheRewards::Reward& out)
{
    std::vector<uint32> eligible;
    {
        std::lock_guard<std::mutex> guard(g_poolLock);
        auto it = g_tokens.find(cacheItemId);
        if (it == g_tokens.end())
            return false;

        for (ContentToken const& token : it->second)
        {
            if (token.stage > g_releasedTokenStage)
                continue;

            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(token.itemId);
            if (!proto || player->CanUseItem(proto) != EQUIP_ERR_OK)
                continue;

            eligible.push_back(token.itemId);
        }
    }

    if (eligible.empty())
        return false;

    out = { eligible[urand(0, uint32(eligible.size() - 1))], 0, 5, 0 };
    return true;
}

bool IsGenericCache(uint32 cacheItemId)
{
    return cacheItemId == GenericCacheAll || cacheItemId == GenericCacheTbc || cacheItemId == GenericCacheWotlk;
}

bool GrantNewestCache(Player* player, Item* item)
{
    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    uint32 cacheItemId = NewestReleasedCache();
    if (!cacheItemId)
    {
        ChatHandler(player->GetSession()).SendSysMessage("No Prestigious Cache is available yet.");
        return true;
    }

    AscensionCacheRewards::Deliver(player, { { cacheItemId, 0, 0, 0 } }, item);
    return true;
}

bool OpenPrestigiousCache(Player* player, Item* item)
{
    if (IsGenericCache(item->GetEntry()))
        return GrantNewestCache(player, item);

    uint32 cacheItemId = item->GetEntry();
    CachePool const* pool = GetPool(cacheItemId);
    if (!pool)
        return false;

    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    if (player->GetLevel() < uint32(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)))
    {
        ChatHandler(player->GetSession()).SendSysMessage("Requires max level to open.");
        return true;
    }

    AscensionCacheRewards::Reward reward;
    if (!PickReward(player, *pool, reward))
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "The cache holds nothing this character can use.");
        return true;
    }

    std::vector<AscensionCacheRewards::Reward> payout = { reward };
    if (roll_chance_i(int32(g_tokenChancePercent)))
    {
        uint32 tokens = roll_chance_i(int32(g_secondTokenChancePercent)) ? 2 : 1;
        for (uint32 index = 0; index < tokens; ++index)
        {
            AscensionCacheRewards::Reward token;
            if (!PickToken(player, cacheItemId, token))
                break;
            payout.push_back(token);
        }
    }

    AscensionCacheRewards::Deliver(player, payout, item);

    return true;
}

class item_ascension_prestigious_cache : public ItemScript
{
public:
    item_ascension_prestigious_cache() : ItemScript("item_ascension_prestigious_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        return OpenPrestigiousCache(player, item);
    }
};

class ascension_prestigious_cache_open : public PlayerScript
{
public:
    ascension_prestigious_cache_open()
        : PlayerScript("ascension_prestigious_cache_open", { PLAYERHOOK_ON_BEFORE_OPEN_ITEM }) { }

    bool OnPlayerBeforeOpenItem(Player* player, Item* item) override
    {
        if (!item || !OpenPrestigiousCache(player, item))
            return true;
        return false;
    }
};

class ascension_prestigious_cache_pools : public WorldScript
{
public:
    ascension_prestigious_cache_pools()
        : WorldScript("ascension_prestigious_cache_pools",
              { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override
    {
        LoadPrestigiousCachePools();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            LoadPrestigiousCachePools();
    }
};
}

void AddSC_AscensionPrestigiousCache()
{
    new item_ascension_prestigious_cache();
    new ascension_prestigious_cache_open();
    new ascension_prestigious_cache_pools();
}
