/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionAverageItemLevel.h"
#include "AscensionCacheRewards.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionRaidReleasePolicy.h"
#include "AscensionSpecLoot.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestDef.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
constexpr uint32 CallboardGeneric = 978050;
constexpr uint32 CallboardGenericOld = 1378050;
constexpr uint32 CallboardGenericVoucher = 1615000;
constexpr uint32 CallboardBonus = 1478050;

constexpr uint16 SMSG_CALLBOARD_CACHE_CONFIG = 0x0730;
constexpr uint16 CMSG_QUERY_CALLBOARD_QUEST_POINTS = 0x0731;
constexpr uint16 SMSG_CALLBOARD_QUEST_POINTS = 0x0732;
constexpr uint16 SMSG_CALLBOARD_TOKEN_UPDATE = 0x0670;
constexpr char CallboardPointsToken[] = "TOKEN_TYPE_CALLBOARD_CACHE_POINTS";
constexpr char CallboardPointsSetting[] = "core.callboard.points";
constexpr char CallboardItemLevelSetting[] = "core.callboard.itemlevel";
constexpr uint32 ReachedItemLevelRecountIndex = 1;
constexpr uint32 ReachedItemLevelRecountVersion = 2;
constexpr uint32 HighestItemLevelReachedCriterion = 80129;
constexpr uint32 PointsPerDisplayedPoint = 10;

struct StagedCache
{
    uint32 stage;
    uint32 cacheItemId;
};

std::array<StagedCache, 9> const CallboardTiers = {{
    { RaidRelease::StageHeroicDungeons, 1615001 },
    { RaidRelease::StageMythicDungeons, 1615002 },
    { RaidRelease::StageMoltenCore, 1615004 },
    { RaidRelease::StageZulGurub, 1615003 },
    { RaidRelease::StageOnyxiasLair, 1615005 },
    { RaidRelease::StageBlackwingLair, 1615006 },
    { RaidRelease::StageAhnQiraj, 1615007 },
    { RaidRelease::StageAhnQiraj, 1615008 },
    { RaidRelease::StageNaxxramas, 1615009 }
}};

using CallboardPool = std::vector<AscensionCacheRewards::Reward>;

struct CacheTier
{
    uint32 itemLevel;
    uint32 cacheItemId;
};

std::mutex g_poolLock;
std::unordered_map<uint32, CallboardPool> g_pools;

std::unordered_map<uint32, uint32> g_questPoints;
std::vector<CacheTier> g_cacheTiers;

uint32 g_itemLevelAllowance = 6;
bool g_previousStageOnly = false;
uint32 g_cachePoints = 150;
uint32 g_goldMin = 5;
uint32 g_goldMax = 15;

void LoadCallboardQuestPoints()
{
    std::unordered_map<uint32, uint32> questPoints;
    if (QueryResult result = WorldDatabase.Query(
            "SELECT `QuestId`, `Points` FROM `ascension_callboard_quest_points`"))
    {
        do
        {
            Field* fields = result->Fetch();
            questPoints[fields[0].Get<uint32>()] = fields[1].Get<uint16>();
        } while (result->NextRow());
    }
    else
    {
        LOG_WARN("coa",
            "ascension_callboard_quest_points is missing: Callboard quests will not fill the cache progress bar.");
    }

    std::lock_guard<std::mutex> guard(g_poolLock);
    g_questPoints = std::move(questPoints);
}

void LoadCallboardCacheTiers()
{
    std::vector<CacheTier> tiers;
    if (QueryResult result = WorldDatabase.Query(
            "SELECT `ItemLevel`, `CacheItemId` FROM `ascension_callboard_cache_tier` "
            "ORDER BY `ItemLevel` DESC"))
    {
        do
        {
            Field* fields = result->Fetch();
            tiers.push_back({ fields[0].Get<uint16>(), fields[1].Get<uint32>() });
        } while (result->NextRow());
    }
    else
    {
        LOG_WARN("coa",
            "ascension_callboard_cache_tier is missing: a full Callboard progress bar will not pay a cache.");
    }

    std::lock_guard<std::mutex> guard(g_poolLock);
    g_cacheTiers = std::move(tiers);
}

void LoadCallboardCachePools()
{
    g_itemLevelAllowance = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.ItemLevelAllowance", 6);
    g_previousStageOnly = sConfigMgr->GetOption<bool>("Ascension.CallboardCache.PreviousStageOnly", false);
    g_cachePoints = std::max<uint32>(1, sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.CachePoints", 150));
    g_goldMin = sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.GoldMin", 5);
    g_goldMax = std::max(g_goldMin, sConfigMgr->GetOption<uint32>("Ascension.CallboardCache.GoldMax", 15));
    LoadCallboardQuestPoints();
    LoadCallboardCacheTiers();

    std::unordered_map<uint32, CallboardPool> pools;
    if (QueryResult result = WorldDatabase.Query(
            "SELECT `CacheItemId`, `RewardItemId`, `RewardItemLevel`, `StatType`, `ArmorClass` "
            "FROM `ascension_callboard_cache_reward`"))
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
            "ascension_callboard_cache_reward is missing: Callboard Caches will not open.");
    }

    std::lock_guard<std::mutex> guard(g_poolLock);
    g_pools = std::move(pools);
}

CallboardPool const* GetPool(uint32 cacheItemId)
{
    std::lock_guard<std::mutex> guard(g_poolLock);
    auto it = g_pools.find(cacheItemId);
    return it == g_pools.end() ? nullptr : &it->second;
}

uint32 HighestItemLevel(CallboardPool const& pool)
{
    uint32 highest = 0;
    for (AscensionCacheRewards::Reward const& reward : pool)
        highest = std::max<uint32>(highest, reward.itemLevel);
    return highest;
}

uint32 HighestStage(uint32 cacheItemId)
{
    uint32 highest = RaidRelease::ReleasedStage();
    if ((g_previousStageOnly || cacheItemId == CallboardGenericOld) && highest > 0)
        --highest;
    return highest;
}

uint32 CacheStage(uint32 cacheItemId)
{
    if (cacheItemId == CallboardGenericVoucher)
        return CallboardTiers.front().stage;
    for (StagedCache const& tier : CallboardTiers)
        if (tier.cacheItemId == cacheItemId)
            return tier.stage;
    return 0;
}

uint32 ResolveGenericTier(Player* player, uint32 cacheItemId)
{
    uint32 const highest = HighestStage(cacheItemId);
    uint32 averageItemLevel = uint32(AscensionAverageItemLevel::Equipped(player));
    uint32 chosen = 0;
    uint32 chosenItemLevel = 0;
    uint32 lowest = 0;

    for (StagedCache const& tier : CallboardTiers)
    {
        if (tier.stage > highest)
            continue;
        CallboardPool const* pool = GetPool(tier.cacheItemId);
        if (!pool || pool->empty())
            continue;
        if (!lowest)
            lowest = tier.cacheItemId;
        uint32 const itemLevel = HighestItemLevel(*pool);
        if (itemLevel <= averageItemLevel + g_itemLevelAllowance && (!chosen || itemLevel >= chosenItemLevel))
        {
            chosen = tier.cacheItemId;
            chosenItemLevel = itemLevel;
        }
    }

    return chosen ? chosen : lowest;
}

bool PickReward(Player* player, CallboardPool const& pool, uint32 averageItemLevel,
    AscensionCacheRewards::Reward& out)
{
    std::vector<AscensionCacheRewards::Reward const*> usable;
    for (AscensionCacheRewards::Reward const& reward : pool)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(reward.itemId);
        if (proto && player->CanUseItem(proto) == EQUIP_ERR_OK)
            usable.push_back(&reward);
    }
    usable = AscensionSpecLoot::PreferSpecialization(player, usable,
        [](AscensionCacheRewards::Reward const* reward) { return sObjectMgr->GetItemTemplate(reward->itemId); });

    std::vector<AscensionCacheRewards::Reward const*> upgrades;
    std::vector<AscensionCacheRewards::Reward const*> reachable;
    for (AscensionCacheRewards::Reward const* reward : usable)
    {
        if (reward->itemLevel > averageItemLevel + g_itemLevelAllowance)
            continue;
        reachable.push_back(reward);
        if (reward->itemLevel >= averageItemLevel)
            upgrades.push_back(reward);
    }

    std::vector<AscensionCacheRewards::Reward const*> const& candidates =
        !upgrades.empty() ? upgrades : (!reachable.empty() ? reachable : usable);
    if (candidates.empty())
        return false;

    out = *candidates[urand(0, uint32(candidates.size() - 1))];
    return true;
}

void GrantGold(Player* player, uint32 copper)
{
    if (!player->ModifyMoney(int32(copper)))
        return;

    WorldPacket notice(SMSG_LOOT_MONEY_NOTIFY, 4 + 1);
    notice << copper << uint8(1);
    player->SendDirectMessage(&notice);
}

bool OpenCallboardCache(Player* player, Item* item)
{
    uint32 cacheItemId = item->GetEntry();
    if (cacheItemId == CallboardGeneric || cacheItemId == CallboardGenericOld ||
        cacheItemId == CallboardGenericVoucher || cacheItemId == CallboardBonus)
    {
        cacheItemId = ResolveGenericTier(player, cacheItemId);
    }

    CallboardPool const* pool = GetPool(cacheItemId);
    if (!pool)
        return false;

    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    AscensionCacheRewards::Reward reward;
    if (!PickReward(player, *pool, uint32(AscensionAverageItemLevel::Equipped(player)), reward))
    {
        ChatHandler(player->GetSession()).SendSysMessage(
            "The cache holds nothing this character can use.");
        return true;
    }

    std::vector<AscensionCacheRewards::Reward> payout = { reward };
    if (AscensionCacheRewards::Deliver(player, payout, item) && g_goldMax)
        GrantGold(player, urand(g_goldMin, g_goldMax) * GOLD);

    return true;
}

uint32 QuestPoints(uint32 questId)
{
    std::lock_guard<std::mutex> guard(g_poolLock);
    auto it = g_questPoints.find(questId);
    return it == g_questPoints.end() ? 0 : it->second;
}

std::vector<CacheTier> ReleasedCacheTiers()
{
    uint32 const stage = RaidRelease::ReleasedStage();
    std::vector<CacheTier> released;
    std::lock_guard<std::mutex> guard(g_poolLock);
    for (CacheTier const& tier : g_cacheTiers)
        if (CacheStage(tier.cacheItemId) <= stage)
            released.push_back(tier);
    return released;
}

uint32 CacheForItemLevel(uint32 itemLevel)
{
    for (CacheTier const& tier : ReleasedCacheTiers())
        if (tier.itemLevel <= itemLevel)
            return tier.cacheItemId;
    return 0;
}

uint32 PointsPerCache()
{
    return g_cachePoints;
}

uint32 StoredPoints(Player const* player)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(CallboardPointsSetting);
    return stored && !stored->empty() ? stored->front().value : 0;
}

uint32 DisplayedProgress(uint32 points)
{
    return points / PointsPerDisplayedPoint;
}

uint32 DisplayedQuestPoints(uint32 points)
{
    return (points + PointsPerDisplayedPoint - 1) / PointsPerDisplayedPoint;
}

void SendPoints(Player* player, uint32 points)
{
    WorldPacket update(SMSG_CALLBOARD_TOKEN_UPDATE, sizeof(CallboardPointsToken) + 2 * sizeof(uint32));
    update << CallboardPointsToken << DisplayedProgress(points) << uint32(0);
    player->SendDirectMessage(&update);
}

void SetPoints(Player* player, uint32 points)
{
    player->UpdatePlayerSetting(CallboardPointsSetting, 0, points);
    SendPoints(player, points);
}

uint32 ReachedItemLevel(Player const* player)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(CallboardItemLevelSetting);
    return stored && !stored->empty() ? stored->front().value : 0;
}

void SendReachedItemLevel(Player* player, uint32 itemLevel)
{
    WorldPacket update(SMSG_CRITERIA_UPDATE, 4 + 8 + 8 + 4 + 4 + 4 + 4);
    update << HighestItemLevelReachedCriterion;
    update.appendPackGUID(itemLevel);
    update << player->GetPackGUID();
    update << uint32(0);
    update.AppendPackedTime(GameTime::GetGameTime().count());
    update << uint32(0) << uint32(0);
    player->SendDirectMessage(&update);
}

void RecountReachedItemLevel(Player* player)
{
    PlayerSettingVector const* stored = player->FindPlayerSettings(CallboardItemLevelSetting);
    if (stored && stored->size() > ReachedItemLevelRecountIndex &&
        (*stored)[ReachedItemLevelRecountIndex].value >= ReachedItemLevelRecountVersion)
        return;

    uint32 const equipped = uint32(AscensionAverageItemLevel::Equipped(player));
    if (ReachedItemLevel(player) > equipped)
        player->UpdatePlayerSetting(CallboardItemLevelSetting, 0, equipped);
    player->UpdatePlayerSetting(CallboardItemLevelSetting, ReachedItemLevelRecountIndex,
        ReachedItemLevelRecountVersion);
}

bool RaiseReachedItemLevel(Player* player)
{
    uint32 const equipped = uint32(AscensionAverageItemLevel::Equipped(player));
    if (equipped <= ReachedItemLevel(player))
        return false;

    player->UpdatePlayerSetting(CallboardItemLevelSetting, 0, equipped);
    return true;
}

void TrackReachedItemLevel(Player* player)
{
    if (RaiseReachedItemLevel(player))
        SendReachedItemLevel(player, ReachedItemLevel(player));
}

void SendCacheConfig(Player* player)
{
    std::vector<CacheTier> const tiers = ReleasedCacheTiers();
    WorldPacket config(SMSG_CALLBOARD_CACHE_CONFIG, (1 + 6 * tiers.size()) * sizeof(uint32));
    config << uint32(tiers.size());
    uint32 recordId = 0;
    for (CacheTier const& tier : tiers)
        config << ++recordId << uint32(0) << uint32(0) << tier.itemLevel << tier.cacheItemId
               << DisplayedProgress(PointsPerCache());
    player->SendDirectMessage(&config);
}

bool GrantCache(Player* player, uint32 cacheItemId)
{
    ItemPosCountVec dest;
    if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, cacheItemId, 1) == EQUIP_ERR_OK)
    {
        if (Item* item = player->StoreNewItem(dest, cacheItemId, true))
        {
            player->SendNewItem(item, 1, true, false);
            return true;
        }
    }

    Item* item = Item::CreateItem(cacheItemId, 1, player);
    if (!item)
        return false;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    item->SaveToDB(trans);
    MailDraft("Callboard Cache", "Your bags were full, so your Callboard Cache was sent by mail.")
        .AddItem(item)
        .SendMailTo(trans, MailReceiver(player), MailSender(player));
    CharacterDatabase.CommitTransaction(trans);
    return true;
}

void AwardQuestPoints(Player* player, uint32 questId)
{
    uint32 const award = QuestPoints(questId);
    if (!award)
        return;

    uint32 points = StoredPoints(player) + award;
    SetPoints(player, points);

    TrackReachedItemLevel(player);
    uint32 const cacheItemId = CacheForItemLevel(ReachedItemLevel(player));
    if (!cacheItemId || !sObjectMgr->GetItemTemplate(cacheItemId))
        return;

    uint32 const threshold = PointsPerCache();
    while (points >= threshold)
    {
        if (!GrantCache(player, cacheItemId))
            break;
        points -= threshold;
        SetPoints(player, points);
    }
}

bool HandleQuestPointsQuery(WorldSession* session, WorldPacket const& packet)
{
    if (!session || packet.size() < sizeof(uint32))
        return true;

    uint32 const questId = packet.read<uint32>(0);
    WorldPacket reply(SMSG_CALLBOARD_QUEST_POINTS, 3 * sizeof(uint32));
    reply << questId << DisplayedQuestPoints(QuestPoints(questId)) << uint32(0);
    session->SendPacket(&reply);
    return true;
}

void SendProgressState(Player* player)
{
    SendCacheConfig(player);
    SendReachedItemLevel(player, ReachedItemLevel(player));
    SendPoints(player, StoredPoints(player));
}

class item_ascension_callboard_cache : public ItemScript
{
public:
    item_ascension_callboard_cache() : ItemScript("item_ascension_callboard_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        return OpenCallboardCache(player, item);
    }
};

class ascension_callboard_cache_open : public PlayerScript
{
public:
    ascension_callboard_cache_open()
        : PlayerScript("ascension_callboard_cache_open", { PLAYERHOOK_ON_BEFORE_OPEN_ITEM }) { }

    bool OnPlayerBeforeOpenItem(Player* player, Item* item) override
    {
        if (!item || !OpenCallboardCache(player, item))
            return true;
        return false;
    }
};

class ascension_callboard_cache_progress : public PlayerScript
{
public:
    ascension_callboard_cache_progress()
        : PlayerScript("ascension_callboard_cache_progress",
              { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP,
                PLAYERHOOK_ON_PLAYER_COMPLETE_QUEST, PLAYERHOOK_ON_EQUIP }) { }

    void OnPlayerLogin(Player* player) override
    {
        RecountReachedItemLevel(player);
        RaiseReachedItemLevel(player);
        SendProgressState(player);
    }

    void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket&) override
    {
        if (player->IsInWorld())
            SendProgressState(player);
    }

    void OnPlayerCompleteQuest(Player* player, Quest const* quest) override
    {
        AwardQuestPoints(player, quest->GetQuestId());
    }

    void OnPlayerEquip(Player* player, Item*, uint8, uint8, bool) override
    {
        if (player->IsInWorld())
            TrackReachedItemLevel(player);
    }
};

class ascension_callboard_cache_pools : public WorldScript
{
public:
    ascension_callboard_cache_pools()
        : WorldScript("ascension_callboard_cache_pools",
              { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override
    {
        LoadCallboardCachePools();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            LoadCallboardCachePools();
    }
};
}

void AddSC_AscensionCallboardCache()
{
    new item_ascension_callboard_cache();
    new ascension_callboard_cache_open();
    new ascension_callboard_cache_progress();
    new ascension_callboard_cache_pools();
    AscensionCompatOpcodes::Claim(CMSG_QUERY_CALLBOARD_QUEST_POINTS, &HandleQuestPointsQuery);
}
