#include "CoAProfessionRescale.h"
#include "CoAProfessionRescaleData.h"
#include "CoAProfessionRescaleRemainingData.h"
#include "DataMap.h"
#include <cassert>
#include <algorithm>
#include <atomic>
#include <mutex>
#include <set>
#include <vector>
#include <map>
#include <utility>

using uint32 = std::uint32_t;
struct ItemTemplate { uint32 ItemLevel, RequiredLevel, RandomProperty; uint32 ItemId = 0; };
struct ObjectMgr
{
    std::map<uint32, ItemTemplate> items;
    ItemTemplate const* GetItemTemplate(uint32 id) const
    {
        auto item = items.find(id);
        return item == items.end() ? nullptr : &item->second;
    }
} objects;
auto* sObjectMgr = &objects;
struct ItemRandomPropertiesEntry { };
struct Store
{
    std::map<uint32, ItemRandomPropertiesEntry> rows;
    ItemRandomPropertiesEntry const* LookupEntry(uint32 id) const
    {
        auto row = rows.find(id);
        return row == rows.end() ? nullptr : &row->second;
    }
} sItemRandomPropertiesStore;
struct WorldSession
{
    bool bot = false;
    std::set<uint32> queries;
    bool IsBot() const { return bot; }
    void SendItemQuerySingleResponse(uint32 entry) { queries.insert(entry); }
};
struct Item;
struct MailItemInfo { uint32 item_guid; };
struct Mail { std::vector<MailItemInfo> items; };
struct Player
{
    std::vector<Mail*> mails;
    std::map<uint32, Item*> mailItems;
    auto const& GetMails() const { return mails; }
    Item* GetMItem(uint32 id) { return mailItems.at(id); }
    WorldSession* session = nullptr;
    WorldSession* GetSession() const { return session; }
    bool inWorld = false;
    bool IsInWorld() const { return inWorld; }
    uint32 getClass() const { return 5; }
};
constexpr int ITEM_CHANGED = 1;
struct Item
{
    uint32 entry;
    std::int32_t property;
    uint32 writes = 0, saves = 0;
    Player* owner = nullptr;
    DataMap CustomData;
    uint32 GetEntry() const { return entry; }
    std::int32_t GetItemRandomPropertyId() const { return property; }
    void SetItemRandomProperties(std::int32_t value) { property = value; ++writes; }
    Player* GetOwner() const { return owner; }
    void SetState(int state, Player*) { assert(state == ITEM_CHANGED); ++saves; }
};
std::map<uint32, ProfessionRescale::Budget> Items;
std::map<std::pair<uint32, std::int32_t>, std::int32_t> PropertyMappings;
constexpr char PendingSaveKey[] = "CoA.ProfessionRescale.PendingSave";
struct PendingSave : DataMap::Base { };
#define LOG_ERROR(...) (void)0
#define LOG_INFO(...) (void)0
enum class AuctionHouseId { Alliance, Horde, Neutral };
struct AuctionEntry { uint32 item_guid; };
struct AuctionHouseObject
{
    std::map<uint32, AuctionEntry*> entries;
    auto const& GetAuctions() const { return entries; }
};
struct AuctionMgr
{
    std::map<AuctionHouseId, AuctionHouseObject> houses;
    std::map<uint32, Item*> items;
    AuctionHouseObject* GetAuctionsMapByHouseId(AuctionHouseId house) { return &houses[house]; }
    Item* GetAItem(uint32 guid) { return items.at(guid); }
} auctions;
auto* sAuctionMgr = &auctions;
// ACTUAL_AUCTIONS
// ACTUAL_LOAD
// ACTUAL_OWNS
// ACTUAL_POWER
// ACTUAL_NORMALIZE
std::atomic<bool> rebornArmor{true};
std::mutex templatesMutex;
std::map<ItemTemplate const*, uint32> scaledRebornArmor;
namespace ItemLadder { bool WearsRebornArmor(uint32) { return true; } }
uint32 AuthoredRebornArmor(ItemTemplate const&) { return 517; }
// ACTUAL_ARMOR
// ACTUAL_REFRESH
bool IsBot(Player const* player) { return !player->session || player->session->IsBot(); }
uint32 mailPreviewProperty = 0;
void SendLevel(Player*, Item const* item) { mailPreviewProperty = item->property; }
// ACTUAL_MAIL

int main()
{
    WorldSession session;
    Player visitor;
    visitor.session = &session;
    RefreshTemplates(&visitor);
    assert(session.queries.empty());
    ProfessionRescale::Load();
    assert(Items.empty() && PropertyMappings.empty());
    for (auto const& row : ProfessionRescale::Budgets)
        objects.items[row.entry] = {row.level, 60, row.propertyPool};
    for (auto const& row : ProfessionRescale::Properties)
        sItemRandomPropertiesStore.rows[row.scaled] = {};
    for (auto const& row : ProfessionRescale::RemainingTbc::Budgets)
        objects.items[row.entry] = {row.level, 60, row.propertyPool};
    for (auto const& row : ProfessionRescale::RemainingTbc::Properties)
        sItemRandomPropertiesStore.rows[row.scaled] = {};
    ProfessionRescale::Load();
    assert(Items.size() == 49 + ProfessionRescale::RemainingTbc::Budgets.size());
    assert(PropertyMappings.size() ==
        ProfessionRescale::Properties.size() + ProfessionRescale::RemainingTbc::Properties.size());
    RefreshTemplates(&visitor);
    assert(session.queries.size() == 298 + ProfessionRescale::RemainingTbc::RefreshEntries.size());
    session.queries.clear();
    session.bot = true;
    RefreshTemplates(&visitor);
    assert(session.queries.empty());
    Player player;
    auto head = objects.items.at(24122);
    head.ItemId = 24122;
    assert(WornArmor(&player, &head, 295) == 295);
    head.ItemId = 999999;
    objects.items[999999] = head;
    assert(WornArmor(&player, &objects.items.at(999999), 295) == 517);
    for (auto const& row : ProfessionRescale::Budgets)
    {
        assert(ProfessionRescale::OwnsItem(row.entry));
        assert(ProfessionRescale::ItemPower(row.entry, false).value() == row.pve);
        assert(ProfessionRescale::ItemPower(row.entry, true).value() == row.pvp);
    }
    auto mapping = *std::find_if(ProfessionRescale::Properties.begin(), ProfessionRescale::Properties.end(),
        [](auto const& row) { return row.original != row.scaled; });
    Item stored{mapping.entry, static_cast<std::int32_t>(mapping.original), 0, 0, nullptr, {}};
    AuctionEntry auction{123};
    auctions.houses[AuctionHouseId::Alliance].entries[1] = &auction;
    auctions.items[123] = &stored;
    ProfessionRescale::Load();
    assert(stored.property == static_cast<std::int32_t>(mapping.scaled) && stored.saves == 0);
    stored.property = mapping.original;
    Mail mail{{{123}}};
    visitor.mails.push_back(&mail);
    visitor.mailItems[123] = &stored;
    session.bot = false;
    MailListed(&visitor);
    assert(stored.property == static_cast<std::int32_t>(mapping.scaled));
    assert(mailPreviewProperty == mapping.scaled);
    auctions.houses.clear();
    auctions.items.clear();
    assert(!ProfessionRescale::OwnsItem(40111) && !ProfessionRescale::ItemPower(40111, false));
    for (auto const& row : ProfessionRescale::Properties)
    {
        Player owner;
        Item item{row.entry, static_cast<std::int32_t>(row.original), 0, 0, &owner, {}};
        ProfessionRescale::NormalizeProperty(&item);
        assert(item.property == static_cast<std::int32_t>(row.scaled));
        assert(item.saves == 0);
        owner.inWorld = true;
        ProfessionRescale::NormalizeProperty(&item);
        assert(item.writes == (row.original != row.scaled ? 1u : 0u));
        assert(item.saves == (row.original != row.scaled ? 1u : 0u));
        ProfessionRescale::NormalizeProperty(&item);
        assert(item.writes == (row.original != row.scaled ? 1u : 0u));
        assert(item.saves == (row.original != row.scaled ? 1u : 0u));
    }
    auto const remainingMapping = ProfessionRescale::RemainingTbc::Properties.front();
    auto const remainingBudget = *std::find_if(ProfessionRescale::RemainingTbc::Budgets.begin(),
        ProfessionRescale::RemainingTbc::Budgets.end(),
        [&](auto const& row) { return row.propertyPool == remainingMapping.entry; });
    Player remainingOwner;
    remainingOwner.inWorld = true;
    Item remaining{remainingBudget.entry, static_cast<std::int32_t>(remainingMapping.original),
        0, 0, &remainingOwner, {}};
    ProfessionRescale::NormalizeProperty(&remaining);
    ProfessionRescale::NormalizeProperty(&remaining);
    assert(remaining.property == static_cast<std::int32_t>(remainingMapping.scaled));
    assert(remaining.writes == 1 && remaining.saves == 1);
    assert(ProfessionRescale::ItemPower(remainingBudget.entry, false) == remainingBudget.pve);
    Item outside{40111, 123, 0, 0, nullptr, {}};
    ProfessionRescale::NormalizeProperty(&outside);
    assert(outside.property == 123 && outside.writes == 0);
    auto const first = ProfessionRescale::Budgets.front();
    objects.items[first.entry].RequiredLevel = 70;
    ProfessionRescale::Load();
    assert(!ProfessionRescale::OwnsItem(first.entry));
    objects.items[first.entry].RequiredLevel = 60;
    objects.items[first.entry].RandomProperty = 13200;
    ProfessionRescale::Load();
    assert(!ProfessionRescale::OwnsItem(first.entry));
}
