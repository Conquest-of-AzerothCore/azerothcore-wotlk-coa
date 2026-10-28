/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionWildcard.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Item.h"
#include "ItemScript.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <algorithm>
#include <mutex>
#include <unordered_set>
#include <vector>

namespace
{
constexpr uint32 WARCHEST_ITEM = 2977351;
constexpr uint8 WARCHEST_LEVEL = 10;

std::mutex g_claimLock;
std::unordered_set<uint32> g_claimedAccounts;

bool ClaimAccount(uint32 accountId)
{
    std::lock_guard<std::mutex> guard(g_claimLock);
    if (!g_claimedAccounts.insert(accountId).second)
        return false;

    return !CharacterDatabase.Query("SELECT 1 FROM coa_account_warchest WHERE account = {}", accountId);
}

void ReleaseAccount(uint32 accountId)
{
    std::lock_guard<std::mutex> guard(g_claimLock);
    g_claimedAccounts.erase(accountId);
}

void GrantWarchest(Player* player)
{
    WorldSession* session = player->GetSession();
    if (session->IsBot() || AscensionWildcard::IsWildcardHero(player))
        return;

    uint32 const accountId = session->GetAccountId();

    if (!sObjectMgr->GetItemTemplate(WARCHEST_ITEM))
    {
        LOG_ERROR("coa", "GrantWarchest: missing item_template entry {} for WARCHEST_ITEM, account {} not granted", WARCHEST_ITEM, accountId);
        return;
    }

    if (!ClaimAccount(accountId))
        return;

    Item* item = Item::CreateItem(WARCHEST_ITEM, 1);
    if (!item)
    {
        ReleaseAccount(accountId);
        return;
    }

    CharacterDatabase.Execute("INSERT IGNORE INTO coa_account_warchest (account, claimed_at) VALUES ({}, {})",
        accountId, uint32(GameTime::GetGameTime().count()));

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    item->SaveToDB(trans);
    MailDraft("Conquest of Azeroth - Elite Warchest",
              "Welcome to Conquest of Azeroth! This warchest is our gift to help you get started on your journey.")
        .AddItem(item)
        .SendMailTo(trans, MailReceiver(player), MailSender(player));
    CharacterDatabase.CommitTransaction(trans);
}

class AscensionWelcomeWarchestPlayerScript : public PlayerScript
{
public:
    AscensionWelcomeWarchestPlayerScript()
        : PlayerScript("AscensionWelcomeWarchestPlayerScript", {PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_LOGIN})
    {
    }

    void OnPlayerLevelChanged(Player* player, uint8) override
    {
        if (player->GetLevel() >= WARCHEST_LEVEL)
            GrantWarchest(player);
    }

    void OnPlayerLogin(Player* player) override
    {
        if (player->GetLevel() >= WARCHEST_LEVEL)
            GrantWarchest(player);
    }
};

struct ChestReward
{
    uint32 Entry;
    uint32 Count;
};

constexpr ChestReward CHEST_REWARDS[] = {
    {2499004, 1},
    {134993, 1},
    {134985, 1},
    {106955, 1},
    {106956, 1},
    {106957, 1},
    {106958, 1},
    {2200034, 2},
    {2200033, 2},
    {134990, 3},
    {696662, 10},
    {777989, 2},
    {134995, 1},
    {134987, 1},
    {1179269, 10},
    {1179261, 10},
    {134994, 10},
    {1179266, 10},
    {1179240, 10},
    {134996, 1},
    {134997, 1},
    {975001, 1500},
    {134989, 1},
    {2977353, 1},
    {696661, 10},
    {696663, 10},
    {696664, 10},
    {696665, 10},
};

constexpr uint32 SCROLL_OF_RETREAT_HORDE = 1175627;
constexpr uint32 SCROLL_OF_RETREAT_ALLIANCE = 1175626;

void DeliverOrQueueMail(Player* player, std::vector<Item*>& mailQueue, uint32 entry, uint32 count)
{
    ItemPosCountVec dest;
    if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, entry, count) == EQUIP_ERR_OK)
    {
        if (Item* item = player->StoreNewItem(dest, entry, true))
            player->SendNewItem(item, count, true, false);
        return;
    }

    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    if (!proto)
        return;

    uint32 const maxStack = std::max<uint32>(1, proto->GetMaxStackSize());
    uint32 remaining = count;
    while (remaining)
    {
        uint32 const stack = std::min(remaining, maxStack);
        if (Item* item = Item::CreateItem(entry, stack))
            mailQueue.push_back(item);
        remaining -= stack;
    }
}

void FlushMailQueue(Player* player, std::vector<Item*> const& mailQueue,
                     char const* subject = "Conquest of Azeroth - Elite Warchest",
                     char const* body = "Your bags were full, so part of your warchest was sent by mail.")
{
    if (mailQueue.empty())
        return;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    for (Item* item : mailQueue)
        item->SaveToDB(trans);

    for (std::size_t index = 0; index < mailQueue.size(); index += MAX_MAIL_ITEMS)
    {
        MailDraft draft(subject, body);

        std::size_t const end = std::min(index + std::size_t(MAX_MAIL_ITEMS), mailQueue.size());
        for (std::size_t i = index; i < end; ++i)
            draft.AddItem(mailQueue[i]);

        draft.SendMailTo(trans, MailReceiver(player), MailSender(player));
    }

    CharacterDatabase.CommitTransaction(trans);
}

void UnlockAllFlightPoints(Player* player)
{
    TeamId const team = player->GetTeamId();
    for (TaxiNodesEntry const* node : sTaxiNodesStore)
    {
        if (!node)
            continue;

        if (sObjectMgr->GetTaxiMountDisplayId(node->ID, team, true))
            player->m_taxi.SetTaximaskNode(node->ID);
    }

    player->SendTaxiNodeStatusMultiple();
}

class item_coa_elite_warchest : public ItemScript
{
public:
    item_coa_elite_warchest() : ItemScript("item_coa_elite_warchest") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        std::vector<Item*> mailQueue;
        for (ChestReward const& reward : CHEST_REWARDS)
            DeliverOrQueueMail(player, mailQueue, reward.Entry, reward.Count);

        uint32 const scrollOfRetreat = player->GetTeamId() == TEAM_HORDE ? SCROLL_OF_RETREAT_HORDE : SCROLL_OF_RETREAT_ALLIANCE;
        DeliverOrQueueMail(player, mailQueue, scrollOfRetreat, 1);

        FlushMailQueue(player, mailQueue);
        UnlockAllFlightPoints(player);

        uint32 count = 1;
        player->DestroyItemCount(item, count, true);
        return true;
    }
};

class item_coa_bag_of_bags : public ItemScript
{
public:
    item_coa_bag_of_bags() : ItemScript("item_coa_bag_of_bags") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        std::vector<Item*> mailQueue;
        DeliverOrQueueMail(player, mailQueue, 1004039, 3);
        FlushMailQueue(player, mailQueue, "Bag of Bags");

        uint32 count = 1;
        player->DestroyItemCount(item, count, true);
        return true;
    }
};
}

void AddSC_AscensionWelcomeWarchest()
{
    new AscensionWelcomeWarchestPlayerScript();
    new item_coa_elite_warchest();
    new item_coa_bag_of_bags();
}
