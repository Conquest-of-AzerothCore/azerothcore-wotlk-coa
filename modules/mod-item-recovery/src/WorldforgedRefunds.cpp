#include "WorldforgedRefunds.h"
#include "Bag.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Item.h"
#include "LocalLevelScaling.h"
#include "Mail.h"
#include "ObjectMgr.h"
#include "Player.h"

#include <algorithm>
#include <memory>
#include <mutex>
#include <utility>

namespace
{
    constexpr uint32 RuneItem = 375250;
    std::mutex offersMutex;
    std::vector<WorldforgedRefunds::Offer> definitions;

    bool Active(WorldforgedRefunds::Offer const& offer)
    {
        auto const now = GameTime::GetGameTime().count();
        return offer.starts <= now && now < offer.ends;
    }

    bool Supported(Player* player, Item* item)
    {
        if (!item || item->GetOwnerGUID() != player->GetGUID() || item->GetCount() != 1 || item->IsEquipped() ||
            item->GetState() != ITEM_UNCHANGED || item->m_lootGenerated ||
            item->GetTemplate()->HasFlag(ITEM_FLAG_HAS_LOOT) ||
            !Player::IsInventoryPos(item->GetBagSlot(), item->GetSlot()) || item->GetValuesCount() != ITEM_END ||
            item->IsWrapped() || item->IsRefundable() || item->IsBOPTradable() || item->IsConjuredConsumable() ||
            item->GetUInt32Value(ITEM_FIELD_DURATION) || item->GetItemRandomPropertyId() || !item->GetText().empty() ||
            !item->GetGuidValue(ITEM_FIELD_CREATOR).IsEmpty() || !item->GetGuidValue(ITEM_FIELD_GIFTCREATOR).IsEmpty() ||
            item->GetUInt32Value(ITEM_FIELD_DURABILITY) != item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY) ||
            LocalLevelScaling::InstanceTemplateFor(item, item->GetTemplate()) != item->GetTemplate())
            return false;
        ItemTemplate const* proto = item->GetTemplate();
        if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR)
            return false;
        for (uint8 slot = 0; slot < MAX_ENCHANTMENT_SLOT; ++slot)
            if (item->GetEnchantmentId(EnchantmentSlot(slot)))
                return false;
        for (uint8 slot = 0; slot < MAX_ITEM_PROTO_SPELLS; ++slot)
            if (item->GetSpellCharges(slot) != proto->Spells[slot].SpellCharges)
                return false;
        return true;
    }

    std::vector<WorldforgedRefunds::Offer> Definitions()
    {
        std::lock_guard<std::mutex> lock(offersMutex);
        return definitions;
    }
}

namespace WorldforgedRefunds
{
void Load()
{
    std::vector<Offer> loaded;
    if (sConfigMgr->GetOption<bool>("ItemRecovery.Enable", true) &&
        sConfigMgr->GetOption<bool>("ItemRecovery.Worldforged.Enable", false) &&
        CharacterDatabase.Query("SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() "
            "AND table_name = 'recovery_worldforged_receipt' AND engine = 'InnoDB'"))
        if (QueryResult rows = WorldDatabase.Query(
            "SELECT id, required_item, refunded_item, rune_count, starts_at, ends_at "
            "FROM recovery_worldforged_offer WHERE enabled = 1 ORDER BY starts_at DESC, id DESC LIMIT 5000"))
            do
            {
                Field* fields = rows->Fetch();
                Offer offer{fields[0].Get<uint32>(), 0, fields[1].Get<uint32>(), fields[2].Get<uint32>(),
                    fields[3].Get<uint32>(), fields[4].Get<uint32>(), fields[5].Get<uint32>()};
                ItemTemplate const* required = sObjectMgr->GetItemTemplate(offer.required);
                ItemTemplate const* refunded = sObjectMgr->GetItemTemplate(offer.refunded);
                ItemTemplate const* runes = sObjectMgr->GetItemTemplate(RuneItem);
                if (!offer.id || !offer.starts || offer.ends <= offer.starts || !required || !refunded ||
                    offer.required == offer.refunded || required->GetMaxStackSize() != 1 ||
                    refunded->GetMaxStackSize() != 1 ||
                    (required->Class != ITEM_CLASS_WEAPON && required->Class != ITEM_CLASS_ARMOR) ||
                    (refunded->Class != ITEM_CLASS_WEAPON && refunded->Class != ITEM_CLASS_ARMOR) ||
                    (offer.runes && (!runes || !runes->GetMaxStackSize() ||
                        uint64(offer.runes) > uint64(runes->GetMaxStackSize()) * (MAX_MAIL_ITEMS - 1))))
                    continue;
                loaded.push_back(offer);
            } while (rows->NextRow());
    std::lock_guard<std::mutex> lock(offersMutex);
    definitions = std::move(loaded);
}

bool Available()
{
    auto const offers = Definitions();
    return std::any_of(offers.begin(), offers.end(), Active);
}

std::string Id(Offer const& offer)
{
    return std::to_string(offer.id) + ":" + std::to_string(offer.originalGuid) + ":" +
        std::to_string(offer.required) + ":" + std::to_string(offer.refunded) + ":" +
        std::to_string(offer.runes) + ":" + std::to_string(offer.starts) + ":" + std::to_string(offer.ends);
}

std::vector<Offer> Offers(Player* player)
{
    std::vector<Offer> offers;
    auto const entries = Definitions();
    auto add = [&](Item* item)
    {
        if (!Supported(player, item) || offers.size() >= 5000)
            return;
        for (Offer offer : entries)
            if (Active(offer) && offer.required == item->GetEntry())
            {
                offer.originalGuid = item->GetGUID().GetCounter();
                offers.push_back(offer);
                if (offers.size() == 5000)
                    break;
            }
    };
    for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
        add(player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot));
    for (uint8 bag = INVENTORY_SLOT_BAG_START; bag < INVENTORY_SLOT_BAG_END; ++bag)
        if (Bag* container = player->GetBagByPos(bag))
            for (uint32 slot = 0; slot < container->GetBagSize(); ++slot)
                add(container->GetItemByPos(slot));
    return offers;
}

char const* Restore(Player* player, Offer const& offer)
{
    auto const entries = Definitions();
    if (!player->IsAlive() || player->GetTradeData() || player->IsBeingTeleported() ||
        !std::any_of(entries.begin(), entries.end(), [&offer](Offer const& entry)
        {
            return Active(entry) && entry.id == offer.id && entry.required == offer.required &&
                entry.refunded == offer.refunded && entry.runes == offer.runes &&
                entry.starts == offer.starts && entry.ends == offer.ends;
        }))
        return "UNKNOWN";
    Item* input = player->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(offer.originalGuid));
    if (!input)
        return "ITEM_NOT_IN_INVENTORY";
    if (!Supported(player, input) || input->GetEntry() != offer.required)
        return "ITEM_NOT_RECOVERABLE";
    std::unique_ptr<Item> refunded(Item::CreateItem(offer.refunded, 1, player, true));
    if (!refunded)
        return "UNKNOWN";
    if (input->IsSoulBound())
        refunded->SetBinding(true);
    uint32 const bag = input->GetContainer() ? input->GetContainer()->GetGUID().GetCounter() : 0;
    QueryResult persisted = CharacterDatabase.Query(
        "SELECT 1 FROM character_inventory AS inventory JOIN item_instance AS item ON item.guid = inventory.item "
        "WHERE inventory.guid = {} AND inventory.item = {} AND inventory.bag = {} AND inventory.slot = {} "
        "AND item.owner_guid = {} AND item.itemEntry = {} AND item.count = 1",
        player->GetGUID().GetCounter(), offer.originalGuid, bag, input->GetSlot(),
        player->GetGUID().GetCounter(), offer.required);
    if (!persisted)
        return "UNKNOWN";
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    MailDraft draft("Worldforged refund", "Your Worldforged exchange is enclosed.");
    refunded->SaveToDB(trans);
    draft.AddItem(refunded.release());
    uint32 remaining = offer.runes;
    while (remaining)
    {
        ItemTemplate const* proto = sObjectMgr->GetItemTemplate(RuneItem);
        if (!proto || !proto->GetMaxStackSize())
        {
            draft.DiscardItems();
            return "UNKNOWN";
        }
        uint32 const count = std::min(remaining, proto->GetMaxStackSize());
        Item* runes = Item::CreateItem(RuneItem, count, player);
        if (!runes)
        {
            draft.DiscardItems();
            return "UNKNOWN";
        }
        runes->SaveToDB(trans);
        draft.AddItem(runes);
        remaining -= count;
    }
    auto staged = draft.StageMailTo(trans, player->GetGUID().GetCounter(), MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM));
    if (!staged)
    {
        draft.DiscardItems();
        return "UNKNOWN";
    }
    trans->Append("INSERT INTO recovery_worldforged_receipt "
        "(offer_id, item_guid, owner_guid, mail_id, required_item, refunded_item, rune_count, claimed_at) "
        "VALUES ({}, (SELECT inventory.item FROM character_inventory AS inventory "
        "JOIN item_instance AS item ON item.guid = inventory.item WHERE inventory.guid = {} "
        "AND inventory.item = {} AND inventory.bag = {} AND inventory.slot = {} "
        "AND item.owner_guid = {} AND item.itemEntry = {} AND item.count = 1 LIMIT 1 FOR UPDATE), "
        "{}, {}, {}, {}, {}, {})", offer.id, player->GetGUID().GetCounter(), offer.originalGuid, bag,
        input->GetSlot(), player->GetGUID().GetCounter(), offer.required,
        player->GetGUID().GetCounter(), staged->mailId, offer.required, offer.refunded, offer.runes,
        uint32(GameTime::GetGameTime().count()));
    trans->Append("DELETE FROM character_inventory WHERE guid = {} AND item = {}",
        player->GetGUID().GetCounter(), offer.originalGuid);
    trans->Append("DELETE FROM item_instance WHERE owner_guid = {} AND guid = {}",
        player->GetGUID().GetCounter(), offer.originalGuid);
    if (!CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())
    {
        draft.DiscardItems();
        return "UNKNOWN";
    }
    player->DestroyItem(input->GetBagSlot(), input->GetSlot(), true);
    draft.PublishStagedMail(*staged, player);
    return "OK";
}
}
