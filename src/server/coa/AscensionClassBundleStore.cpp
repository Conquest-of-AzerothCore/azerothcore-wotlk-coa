/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCompatOpcodes.h"

#include "../../../modules/mod-worldforged-upgrades/src/WorldforgedUpgrades.h"

#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <vector>

namespace
{
constexpr uint32 STORE_CLASS_BUNDLE_1 = 10;
constexpr uint32 STORE_CLASS_BUNDLE_2 = 11;
constexpr uint32 CURRENCY_CLASS_BUNDLE_1 = 2499003;
constexpr uint32 CURRENCY_CLASS_BUNDLE_2 = 2499004;
constexpr uint32 CLASS_BUNDLE_FIRST = 2615021;
constexpr uint32 CLASS_BUNDLE_LAST = 2615041;

std::vector<uint32> g_bundles;

void LoadBundles()
{
    g_bundles.clear();
    for (uint32 entry = CLASS_BUNDLE_FIRST; entry <= CLASS_BUNDLE_LAST; ++entry)
        if (sObjectMgr->GetItemTemplate(entry))
            g_bundles.push_back(entry);

    LOG_INFO("module.ascension_compat",
             "AscensionClassBundleStore: {} of {} class bundles found in item_template.",
             g_bundles.size(), CLASS_BUNDLE_LAST - CLASS_BUNDLE_FIRST + 1);
}

bool IsBundle(uint32 entry)
{
    for (uint32 bundle : g_bundles)
        if (bundle == entry)
            return true;
    return false;
}

uint32 CurrencyForStore(uint32 store)
{
    return store == STORE_CLASS_BUNDLE_2 ? CURRENCY_CLASS_BUNDLE_2 : CURRENCY_CLASS_BUNDLE_1;
}

void BuildStoreRecord(ByteBuffer& out, uint32 bundleEntry, uint32 store)
{
    std::size_t const start = out.wpos();

    out << uint32(bundleEntry);
    out << uint32(store);
    out << uint32(bundleEntry);
    out << uint32(0);

    uint32 items[5] = { CurrencyForStore(store), 0, 0, 0, 0 };
    uint32 counts[5] = { 1, 0, 0, 0, 0 };
    for (uint32 id : items)
        out << id;
    for (uint32 n : counts)
        out << n;

    out << uint32(0);
    out << uint32(0);

    ASSERT(out.wpos() - start == Worldforged::RECORD_SIZE);
}

void SendPurchaseResult(WorldSession* session, char const* result)
{
    WorldPacket packet(Worldforged::SMSG_PURCHASE_CUSTOM_STORE_ITEM_RESULT, 32);
    packet << result;
    session->SendPacket(&packet);
}

bool HandleQuery(WorldSession* session, WorldPacket const& packet)
{
    Player* player = session->GetPlayer();
    if (!player)
        return false;

    WorldPacket read(packet);
    uint32 store = 0;
    read >> store;

    if (store != STORE_CLASS_BUNDLE_1 && store != STORE_CLASS_BUNDLE_2)
        return false;

    WorldPacket result(Worldforged::SMSG_QUERY_CUSTOM_STORE_RESULT,
                       32 + g_bundles.size() * Worldforged::RECORD_SIZE);
    result << Worldforged::RESULT_QUERY_OK;
    result << uint32(g_bundles.size());
    for (uint32 bundle : g_bundles)
        BuildStoreRecord(result, bundle, store);

    session->SendPacket(&result);

    LOG_INFO("module.ascension_compat", "AscensionClassBundleStore: sent store {} to {} with {} bundles.",
             store, player->GetName(), g_bundles.size());
    return true;
}

bool HandlePurchase(WorldSession* session, WorldPacket const& packet)
{
    Player* player = session->GetPlayer();
    if (!player)
        return false;

    WorldPacket read(packet);
    uint32 key = 0;
    uint32 quantity = 0;
    read >> key >> quantity;

    if (!IsBundle(key))
        return false;

    uint32 currency = 0;
    if (player->HasItemCount(CURRENCY_CLASS_BUNDLE_2, 1, true))
        currency = CURRENCY_CLASS_BUNDLE_2;
    else if (player->HasItemCount(CURRENCY_CLASS_BUNDLE_1, 1, true))
        currency = CURRENCY_CLASS_BUNDLE_1;
    else
    {
        SendPurchaseResult(session, "You do not have a Conquest of Azeroth Class Bundle.");
        return true;
    }

    ItemPosCountVec destination;
    InventoryResult const fits =
        player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, key, 1);
    if (fits != EQUIP_ERR_OK)
    {
        player->SendEquipError(fits, nullptr, nullptr, key);
        SendPurchaseResult(session, "You have no room for the class bundle.");
        return true;
    }

    player->DestroyItemCount(currency, 1, true);

    if (Item* given = player->StoreNewItem(destination, key, true,
                                           Item::GenerateItemRandomPropertyId(key)))
        player->SendNewItem(given, 1, true, false);

    SendPurchaseResult(session, Worldforged::RESULT_PURCHASE_OK);

    LOG_INFO("module.ascension_compat",
             "AscensionClassBundleStore: {} bought bundle {} for {} currency {}.",
             player->GetName(), key, 1, currency);

    (void)quantity;
    return true;
}

class ascension_class_bundle_store_world : public WorldScript
{
public:
    ascension_class_bundle_store_world() : WorldScript("ascension_class_bundle_store_world") { }

    void OnStartup() override { LoadBundles(); }
};

class item_coa_class_bundle_token : public ItemScript
{
public:
    item_coa_class_bundle_token() : ItemScript("item_coa_class_bundle_token") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        uint32 const store = item->GetEntry() == CURRENCY_CLASS_BUNDLE_1
            ? STORE_CLASS_BUNDLE_1 : STORE_CLASS_BUNDLE_2;

        WorldPacket packet(Worldforged::SMSG_OPEN_CUSTOM_STORE, 4);
        packet << uint32(store);
        player->GetSession()->SendPacket(&packet);
        return true;
    }
};
}

void AddSC_AscensionClassBundleStore()
{
    AscensionCompatOpcodes::Claim(Worldforged::CMSG_QUERY_CUSTOM_STORE, &HandleQuery);
    AscensionCompatOpcodes::Claim(Worldforged::CMSG_PURCHASE_CUSTOM_STORE_ITEM, &HandlePurchase);

    new ascension_class_bundle_store_world();
    new item_coa_class_bundle_token();
}
