/*
 * The set caches Ascension already shipped.
 *
 * "Tormented Ashdevil's Set Cache" and 668 others hold a fixed list of pieces
 * rather than a random draw. The client knows that list - VanityCollection
 * carries it in sixteen columns - so nothing here is inferred from names.
 *
 * Unlike a lost cache, a set cache gives EVERYTHING it holds at once. That is
 * what a set cache is: the player bought the set, not a lottery ticket.
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
#include "ScriptMgr.h"

#include <unordered_map>
#include <vector>

namespace
{
    std::unordered_map<uint32, std::vector<uint32>> g_setCaches;

    void LoadSetCaches()
    {
        g_setCaches.clear();

        QueryResult result = WorldDatabase.Query(
            "SELECT cache_item, member_item FROM ethereal_bazaar_set_cache ORDER BY cache_item, idx");
        if (!result)
        {
            LOG_WARN("module.bazaar", "Ethereal Bazaar: no set cache contents defined.");
            return;
        }

        uint32 skipped = 0;
        do
        {
            Field* f = result->Fetch();
            uint32 const cache = f[0].Get<uint32>();
            uint32 const member = f[1].Get<uint32>();

            if (!sObjectMgr->GetItemTemplate(member))
            {
                ++skipped;
                continue;
            }
            g_setCaches[cache].push_back(member);
        } while (result->NextRow());

        std::size_t total = 0;
        for (auto const& [cache, members] : g_setCaches)
            total += members.size();
        LOG_INFO("module.bazaar", "Ethereal Bazaar: {} set caches with {} pieces{}.",
                 g_setCaches.size(), total,
                 skipped ? Acore::StringFormat(", {} skipped as unknown", skipped) : "");
    }
}

class item_ethereal_set_cache : public ItemScript
{
public:
    item_ethereal_set_cache() : ItemScript("item_ethereal_set_cache") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        auto const it = g_setCaches.find(item->GetEntry());
        if (it == g_setCaches.end() || it->second.empty())
        {
            ChatHandler(player->GetSession()).PSendSysMessage("This cache is empty. Tell an administrator.");
            return true;
        }

        // Every piece has to fit before anything is handed over. Opening a
        // nine-piece set into two free slots and losing seven of them would be
        // the kind of bug a player never forgives.
        ItemPosCountVec dest;
        for (uint32 member : it->second)
        {
            ItemPosCountVec one;
            InventoryResult const check = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, one, member, 1);
            if (check != EQUIP_ERR_OK)
            {
                player->SendEquipError(check, nullptr, nullptr, member);
                return true;
            }
        }

        player->DestroyItemCount(item->GetEntry(), 1, true);
        for (uint32 member : it->second)
        {
            ItemPosCountVec one;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, one, member, 1) != EQUIP_ERR_OK)
                continue;
            if (Item* given = player->StoreNewItem(one, member, true, Item::GenerateItemRandomPropertyId(member)))
                player->SendNewItem(given, 1, true, false);
        }

        LOG_DEBUG("module.bazaar", "Ethereal Bazaar: {} opened set cache {} for {} pieces.",
                  player->GetName(), item->GetEntry(), it->second.size());
        return true;
    }
};

class ethereal_bazaar_set_cache_world : public WorldScript
{
public:
    ethereal_bazaar_set_cache_world() : WorldScript("ethereal_bazaar_set_cache_world") { }

    void OnStartup() override { LoadSetCaches(); }
};

void AddEtherealBazaarSetCacheScripts()
{
    new item_ethereal_set_cache();
    new ethereal_bazaar_set_cache_world();
}
