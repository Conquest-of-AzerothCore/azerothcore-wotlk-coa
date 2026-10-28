/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCacheRewards.h"
#include "AscensionRaidReleasePolicy.h"
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
#include <memory>
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
std::unordered_map<uint32, std::shared_ptr<CachePool const>> g_pools;
std::unordered_map<uint32, std::vector<ContentToken>> g_tokens;

struct CacheConfig
{
    uint32 tokenChancePercent = 25;
    uint32 secondTokenChancePercent = 5;
    uint8 releasedTokenStage = 12;
    uint8 classicStages = 8;
    uint8 tbcStages = 0;
};

CacheConfig g_config;

CacheConfig CurrentConfig()
{
    std::lock_guard<std::mutex> guard(g_poolLock);
    return g_config;
}

uint32 ClassicStage(uint32 cacheItemId)
{
    switch (cacheItemId)
    {
        case 1287304: return RaidRelease::StageHeroicDungeons;
        case 1287305: return RaidRelease::StageZulGurub;
        case 1287306: return RaidRelease::StageMoltenCore;
        case 1287307: return RaidRelease::StageOnyxiasLair;
        case 1287308: return RaidRelease::StageBlackwingLair;
        case 1287309:
        case 1287310: return RaidRelease::StageAhnQiraj;
        case 1287311: return RaidRelease::StageNaxxramas;
        default: return 0;
    }
}

bool IsCacheReleased(uint32 cacheItemId, CacheConfig const& config)
{
    uint32 const released = RaidRelease::ReleasedStage();
    for (std::size_t index = 0; index < ClassicLadder.size(); ++index)
        if (ClassicLadder[index] == cacheItemId)
            return index < config.classicStages && ClassicStage(cacheItemId) <= released;

    for (std::size_t index = 0; index < TbcLadder.size(); ++index)
        if (TbcLadder[index] == cacheItemId)
            return sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL) >= 70 && index < config.tbcStages;
    return false;
}

bool IsTokenReleased(uint8 tokenStage, uint32 cacheItemId)
{
    uint32 stage = 0;
    switch (tokenStage)
    {
        case 2: stage = RaidRelease::StageMoltenCore; break;
        case 4: stage = cacheItemId == 1287307 ? RaidRelease::StageOnyxiasLair :
            RaidRelease::StageBlackwingLair; break;
        case 5: stage = RaidRelease::StageAhnQiraj; break;
        case 6: stage = RaidRelease::StageNaxxramas; break;
        default: return tokenStage >= 8 && sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL) >= 70;
    }
    return stage <= RaidRelease::ReleasedStage();
}

void LoadPrestigiousCachePools()
{
    CacheConfig config;
    config.tokenChancePercent = std::min<uint32>(
        sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.TokenChancePercent", 25), 100);
    config.secondTokenChancePercent = std::min<uint32>(
        sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.SecondTokenChancePercent", 5), 100);
    config.releasedTokenStage = uint8(std::min<uint32>(
        sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.ReleaseStage", 6), 6) * 2);
    config.classicStages = uint8(std::min<uint32>(
        sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.ClassicStages", 8), ClassicLadder.size()));
    config.tbcStages = uint8(std::min<uint32>(
        sConfigMgr->GetOption<uint32>("Ascension.PrestigiousCache.TbcStages", 0), TbcLadder.size()));

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

    std::unordered_map<uint32, std::shared_ptr<CachePool const>> snapshots;
    for (auto& [cacheItemId, pool] : pools)
        snapshots.emplace(cacheItemId, std::make_shared<CachePool const>(std::move(pool)));

    std::lock_guard<std::mutex> guard(g_poolLock);
    g_config = config;
    g_pools = std::move(snapshots);
    g_tokens = std::move(tokens);
}

std::shared_ptr<CachePool const> GetPool(uint32 cacheItemId)
{
    std::lock_guard<std::mutex> guard(g_poolLock);
    auto it = g_pools.find(cacheItemId);
    return it == g_pools.end() ? nullptr : it->second;
}

uint32 NewestReleasedTier(std::vector<uint32> const& ladder, CacheConfig const& config)
{
    uint32 resolved = 0;
    for (uint32 cacheItemId : ladder)
    {
        if (!IsCacheReleased(cacheItemId, config))
            continue;
        std::shared_ptr<CachePool const> pool = GetPool(cacheItemId);
        if (pool && !pool->empty())
            resolved = cacheItemId;
    }
    return resolved;
}

uint32 NewestReleasedCache(uint32 genericCacheItemId, CacheConfig const& config)
{
    if (genericCacheItemId == GenericCacheWotlk)
        return 0;
    if (genericCacheItemId == GenericCacheTbc)
        return NewestReleasedTier(TbcLadder, config);
    if (config.tbcStages && sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL) >= 70)
        if (uint32 const tier = NewestReleasedTier(TbcLadder, config))
            return tier;
    return NewestReleasedTier(ClassicLadder, config);
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

bool PickToken(Player* player, uint32 cacheItemId, CacheConfig const& config,
    AscensionCacheRewards::Reward& out)
{
    if (!IsCacheReleased(cacheItemId, config))
        return false;

    std::vector<uint32> eligible;
    {
        std::lock_guard<std::mutex> guard(g_poolLock);
        auto it = g_tokens.find(cacheItemId);
        if (it == g_tokens.end())
            return false;

        for (ContentToken const& token : it->second)
        {
            if (token.stage > config.releasedTokenStage || !IsTokenReleased(token.stage, cacheItemId))
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

    uint32 cacheItemId = NewestReleasedCache(item->GetEntry(), CurrentConfig());
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
    std::shared_ptr<CachePool const> pool = GetPool(cacheItemId);
    if (!pool)
    {
        if (!ClassicStage(cacheItemId) &&
            std::find(TbcLadder.begin(), TbcLadder.end(), cacheItemId) == TbcLadder.end())
            return false;
        ChatHandler(player->GetSession()).SendSysMessage("This Prestigious Cache has no configured rewards.");
        return true;
    }

    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    if (player->GetLevel() < uint32(sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)))
    {
        ChatHandler(player->GetSession()).SendSysMessage("Requires max level to open.");
        return true;
    }

    CacheConfig const config = CurrentConfig();
    if (!IsCacheReleased(cacheItemId, config))
    {
        ChatHandler(player->GetSession()).SendSysMessage("This Prestigious Cache is not released yet.");
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
    if (roll_chance_i(int32(config.tokenChancePercent)))
    {
        uint32 tokens = roll_chance_i(int32(config.secondTokenChancePercent)) ? 2 : 1;
        for (uint32 index = 0; index < tokens; ++index)
        {
            AscensionCacheRewards::Reward token;
            if (!PickToken(player, cacheItemId, config, token))
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
