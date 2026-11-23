/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionRealmLevelPurchase.h"

#include "AscensionAccountProgress.h"
#include "Chat.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"

#include <string_view>
#include <unordered_set>
#include <utility>

namespace
{
constexpr uint8 REALM_LEVEL = 60;
constexpr std::string_view REFUSAL = "You need to have reached level 60 at least once on this realm to buy this item.";

std::unordered_set<uint32> g_items;

void LoadItems()
{
    std::unordered_set<uint32> items;
    if (QueryResult result = WorldDatabase.Query("SELECT `ItemID` FROM `coa_item_purchase_requires_realm_level_60`"))
    {
        do
        {
            items.insert(result->Fetch()[0].Get<uint32>());
        } while (result->NextRow());
    }

    g_items = std::move(items);
    LOG_INFO("server.loading", ">> Loaded {} items that need a level 60 on the realm to buy", g_items.size());
}

class ascension_realm_level_purchase_world : public WorldScript
{
public:
    ascension_realm_level_purchase_world()
        : WorldScript("ascension_realm_level_purchase_world", { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnStartup() override
    {
        LoadItems();
    }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            LoadItems();
    }
};

class ascension_realm_level_purchase_vendor : public PlayerScript
{
public:
    ascension_realm_level_purchase_vendor()
        : PlayerScript("ascension_realm_level_purchase_vendor", { PLAYERHOOK_ON_BEFORE_BUY_ITEM_FROM_VENDOR }) { }

    void OnPlayerBeforeBuyItemFromVendor(Player* player, ObjectGuid, uint32, uint32& item, uint8, uint8, uint8) override
    {
        if (item && AscensionRealmLevelPurchase::Refuse(player, item))
            item = 0;
    }
};
}

bool AscensionRealmLevelPurchase::Refuse(Player* player, uint32 itemId)
{
    if (!player || !g_items.contains(itemId) || AscensionAccountProgress::HasLevelOrPrestige(player, REALM_LEVEL))
        return false;

    ChatHandler handler(player->GetSession());
    handler.SendNotification(REFUSAL);
    handler.SendSysMessage(REFUSAL);
    return true;
}

void AddSC_AscensionRealmLevelPurchase()
{
    new ascension_realm_level_purchase_world();
    new ascension_realm_level_purchase_vendor();
}
