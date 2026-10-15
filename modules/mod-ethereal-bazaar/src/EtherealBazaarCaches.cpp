/*
 * The caches that hold one random item.
 *
 * LOST CACHES stand for one vanity category each and hold the items of that
 * category whose only source was the webshop. Opening one gives a random item
 * the player does not already own, so a second cache is never a duplicate of
 * the first while anything is left to find.
 *
 * The ETHEREAL CACHE OF WARES is Ascension's own, sold from the first row of
 * the rotating list, and draws from the whole bazaar pool instead. It does NOT
 * prefer unowned items, and that is deliberate: at 250 tokens against a pool
 * whose average row is worth 469, a cache that guaranteed something new would
 * be a cheaper route to the entire collection than the rotation it sits in.
 * Rolling blind means it quietly gets worse as a collection fills up.
 */

#include "EtherealBazaar.h"

#include "Chat.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "QueryResult.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"

#include <unordered_map>
#include <vector>

namespace
{
    std::unordered_map<uint32, std::vector<uint32>> g_cachePools;

    std::vector<uint32> g_waresPool;

    void LoadWaresPool()
    {
        g_waresPool.clear();

        QueryResult result = WorldDatabase.Query("SELECT item FROM ethereal_bazaar_pool");
        if (!result)
        {
            LOG_WARN("module.bazaar", "Ethereal Bazaar: the pool is empty, "
                                      "the Ethereal Cache of Wares has nothing to give.");
            return;
        }

        do
        {
            uint32 const item = result->Fetch()[0].Get<uint32>();
            if (sObjectMgr->GetItemTemplate(item))
                g_waresPool.push_back(item);
        } while (result->NextRow());

        LOG_INFO("module.bazaar", "Ethereal Bazaar: cache of wares draws from {} items.",
                 g_waresPool.size());
    }

    void LoadCachePools()
    {
        g_cachePools.clear();

        QueryResult result = WorldDatabase.Query(
            "SELECT cache_item, reward_item FROM ethereal_bazaar_cache_pool");
        if (!result)
        {
            LOG_WARN("module.bazaar", "Ethereal Bazaar: no lost cache contents defined.");
            return;
        }

        uint32 skipped = 0;
        do
        {
            Field* f = result->Fetch();
            uint32 const cache = f[0].Get<uint32>();
            uint32 const reward = f[1].Get<uint32>();

            if (!sObjectMgr->GetItemTemplate(reward))
            {
                ++skipped;
                continue;
            }
            g_cachePools[cache].push_back(reward);
        } while (result->NextRow());

        std::size_t total = 0;
        for (auto const& [cache, items] : g_cachePools)
            total += items.size();
        LOG_INFO("module.bazaar", "Ethereal Bazaar: {} lost caches with {} possible items{}.",
                 g_cachePools.size(), total,
                 skipped ? Acore::StringFormat(", {} skipped as unknown", skipped) : "");
    }
}

class item_ethereal_lost_cache : public ItemScript
{
public:
    item_ethereal_lost_cache() : ItemScript("item_ethereal_lost_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        auto const it = g_cachePools.find(item->GetEntry());
        if (it == g_cachePools.end() || it->second.empty())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("This cache is empty. Tell an administrator.");
            return true;   // true = handled; the item is not consumed
        }

        // Prefer something the player has not got yet. Only when everything in
        // the category is already owned do we fall back to any of them - a
        // cache that refuses to open would be worse than a duplicate.
        std::vector<uint32> wanted;
        wanted.reserve(it->second.size());
        for (uint32 reward : it->second)
            if (!player->HasItemCount(reward, 1, true))
                wanted.push_back(reward);

        std::vector<uint32> const& from = wanted.empty() ? it->second : wanted;
        uint32 const reward = from[urand(0, static_cast<uint32>(from.size()) - 1)];

        // One free slot is needed for the reward, and the cache itself only
        // frees its own slot after it is destroyed. Check before taking it.
        ItemPosCountVec dest;
        InventoryResult const check = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, reward, 1);
        if (check != EQUIP_ERR_OK)
        {
            player->SendEquipError(check, nullptr, nullptr, reward);
            return true;
        }

        player->DestroyItemCount(item->GetEntry(), 1, true);
        if (Item* given = player->StoreNewItem(dest, reward, true, Item::GenerateItemRandomPropertyId(reward)))
            player->SendNewItem(given, 1, true, false);

        LOG_DEBUG("module.bazaar", "Ethereal Bazaar: {} opened cache {} and received item {}.",
                  player->GetName(), item->GetEntry(), reward);
        return true;
    }
};

class item_ethereal_cache_of_wares : public ItemScript
{
public:
    item_ethereal_cache_of_wares() : ItemScript("item_ethereal_cache_of_wares") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (g_waresPool.empty())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("This cache is empty. Tell an administrator.");
            return true;   // true = handled; the item is not consumed
        }

        uint32 const reward = g_waresPool[urand(0, static_cast<uint32>(g_waresPool.size()) - 1)];

        // One free slot is needed for the reward, and the cache only frees its
        // own slot after it is destroyed. Check before taking it.
        ItemPosCountVec dest;
        InventoryResult const check = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, reward, 1);
        if (check != EQUIP_ERR_OK)
        {
            player->SendEquipError(check, nullptr, nullptr, reward);
            return true;
        }

        player->DestroyItemCount(item->GetEntry(), 1, true);
        if (Item* given = player->StoreNewItem(dest, reward, true, Item::GenerateItemRandomPropertyId(reward)))
            player->SendNewItem(given, 1, true, false);

        LOG_DEBUG("module.bazaar", "Ethereal Bazaar: {} opened a cache of wares and received item {}.",
                  player->GetName(), reward);
        return true;
    }
};

class ethereal_bazaar_cache_world : public WorldScript
{
public:
    ethereal_bazaar_cache_world() : WorldScript("ethereal_bazaar_cache_world") { }

    void OnStartup() override
    {
        LoadCachePools();
        LoadWaresPool();
    }
};

void AddEtherealBazaarCacheScripts()
{
    new item_ethereal_lost_cache();
    new item_ethereal_cache_of_wares();
    new ethereal_bazaar_cache_world();
}
