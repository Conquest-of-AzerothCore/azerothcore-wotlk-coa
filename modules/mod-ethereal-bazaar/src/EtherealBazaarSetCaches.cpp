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
#include "Mail.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <unordered_map>
#include <vector>

namespace
{
    std::unordered_map<uint32, std::vector<std::pair<uint32, uint32>>> g_setCaches;

    void LoadSetCaches()
    {
        g_setCaches.clear();

        QueryResult result = WorldDatabase.Query(
            "SELECT cache_item, member_item, count FROM ethereal_bazaar_set_cache ORDER BY cache_item, idx");
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
            uint32 const count = std::max<uint32>(1, f[2].Get<uint8>());

            if (!sObjectMgr->GetItemTemplate(member))
            {
                ++skipped;
                continue;
            }
            g_setCaches[cache].emplace_back(member, count);
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

        uint32 const cacheEntry = item->GetEntry();
        player->DestroyItemCount(cacheEntry, 1, true);

        std::vector<Item*> mail;
        for (auto const& [member, count] : it->second)
        {
            uint32 const stackSize = std::max<uint32>(1, sObjectMgr->GetItemTemplate(member)->GetMaxStackSize());
            for (uint32 left = count; left > 0;)
            {
                uint32 const stack = std::min(left, stackSize);
                left -= stack;

                ItemPosCountVec dest;
                if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, member, stack) == EQUIP_ERR_OK)
                {
                    if (Item* given = player->StoreNewItem(dest, member, true, Item::GenerateItemRandomPropertyId(member)))
                        player->SendNewItem(given, stack, true, false);
                }
                else if (Item* piece = Item::CreateItem(member, stack, player))
                    mail.push_back(piece);
            }
        }

        if (!mail.empty())
        {
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            for (std::size_t index = 0; index < mail.size(); index += MAX_MAIL_ITEMS)
            {
                MailDraft draft("Set cache", "Your bags were full, so the rest of your set was sent by mail.");
                for (std::size_t i = index; i < std::min(index + std::size_t(MAX_MAIL_ITEMS), mail.size()); ++i)
                {
                    mail[i]->SaveToDB(trans);
                    draft.AddItem(mail[i]);
                }
                draft.SendMailTo(trans, MailReceiver(player), MailSender(player));
            }
            CharacterDatabase.CommitTransaction(trans);
        }

        LOG_DEBUG("module.bazaar", "Ethereal Bazaar: {} opened set cache {} for {} pieces.",
                  player->GetName(), cacheEntry, it->second.size());
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
