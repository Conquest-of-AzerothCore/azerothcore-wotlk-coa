/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CoAProfessionRescale.h"
#include "CoAProfessionRescaleData.h"
#include "CoAProfessionRescaleRemainingData.h"
#include "DBCStores.h"
#include "AuctionHouseMgr.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "WorldSession.h"
#include <map>
#include <set>
#include <utility>

namespace
{
std::map<std::uint32_t, ProfessionRescale::Budget> Items;
std::map<std::pair<std::uint32_t, std::int32_t>, std::int32_t> PropertyMappings;
constexpr char PendingSaveKey[] = "CoA.ProfessionRescale.PendingSave";
struct PendingSave : DataMap::Base { };

void NormalizeAuctions()
{
    for (AuctionHouseId house : {AuctionHouseId::Alliance, AuctionHouseId::Horde, AuctionHouseId::Neutral})
        if (AuctionHouseObject* auctions = sAuctionMgr->GetAuctionsMapByHouseId(house))
            for (auto const& [id, auction] : auctions->GetAuctions())
                ProfessionRescale::NormalizeProperty(sAuctionMgr->GetAItem(auction->item_guid));
}

void RefreshTemplates(Player* player)
{
    WorldSession* session = player->GetSession();
    if (!session || session->IsBot() || Items.empty())
        return;
    for (std::uint32_t entry : ProfessionRescale::RefreshEntries)
        session->SendItemQuerySingleResponse(entry);
    for (std::uint32_t entry : ProfessionRescale::RemainingTbc::RefreshEntries)
        session->SendItemQuerySingleResponse(entry);
}

class ProfessionClientItems final : public PlayerScript
{
public:
    ProfessionClientItems() : PlayerScript("ProfessionClientItems", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        RefreshTemplates(player);
    }
};
}

void ProfessionRescale::Load()
{
    Items.clear();
    PropertyMappings.clear();
    auto loadBudgets = [](auto const& budgets)
    {
        for (Budget const& row : budgets)
        {
            ItemTemplate const* item = sObjectMgr->GetItemTemplate(row.entry);
            if (!item || item->ItemLevel != row.level || item->RequiredLevel > 60 ||
                item->RandomProperty != row.propertyPool)
                continue;
            Items.emplace(row.entry, row);
        }
    };
    loadBudgets(Budgets);
    loadBudgets(RemainingTbc::Budgets);

    std::set<std::uint32_t> activePools;
    for (auto const& [entry, budget] : Items)
        if (budget.propertyPool)
            activePools.insert(budget.propertyPool);

    auto loadProperty = [](std::uint32_t pool, Property const& row)
    {
        if (!sItemRandomPropertiesStore.LookupEntry(row.scaled))
        {
            LOG_ERROR("server.loading", "Missing profession item property {} for pool {}", row.scaled, pool);
            return;
        }
        PropertyMappings.emplace(std::make_pair(pool, row.original), row.scaled);
    };
    for (Property const& row : ProfessionRescale::Properties)
        if (auto const item = Items.find(row.entry); item != Items.end())
            loadProperty(item->second.propertyPool, row);
    for (Property const& row : RemainingTbc::Properties)
        if (activePools.count(row.entry))
            loadProperty(row.entry, row);
    NormalizeAuctions();
    LOG_INFO("server.loading", "Loaded {} fixed profession item budgets and {} affix mappings",
        Items.size(), PropertyMappings.size());
}

bool ProfessionRescale::OwnsItem(std::uint32_t entry)
{
    return Items.count(entry) != 0;
}

std::optional<std::uint32_t> ProfessionRescale::ItemPower(std::uint32_t entry, bool pvp)
{
    auto const row = Items.find(entry);
    return row == Items.end() ? std::nullopt :
        std::optional<std::uint32_t>(pvp ? row->second.pvp : row->second.pve);
}

void ProfessionRescale::NormalizeProperty(Item* item)
{
    if (!item)
        return;
    auto const budget = Items.find(item->GetEntry());
    if (budget == Items.end())
        return;
    auto const property = PropertyMappings.find({budget->second.propertyPool, item->GetItemRandomPropertyId()});
    if (property != PropertyMappings.end() && property->second != item->GetItemRandomPropertyId())
    {
        item->SetItemRandomProperties(property->second);
        item->CustomData.GetDefault<PendingSave>(PendingSaveKey);
    }
    if (item->CustomData.Get<PendingSave>(PendingSaveKey))
        if (Player* owner = item->GetOwner(); owner && owner->IsInWorld())
        {
            item->SetState(ITEM_CHANGED, owner);
            item->CustomData.Erase(PendingSaveKey);
        }
}

void AddSC_CoAProfessionRescale()
{
    new ProfessionClientItems();
}
