#include "ExactItemRecovery.h"
#include "AscensionItemRecovery.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Item.h"
#include "Mail.h"
#include "LocalLevelScaling.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldSession.h"

#include <algorithm>
#include <atomic>
#include <memory>
#include <mutex>
#include <sstream>
#include <unordered_map>

namespace
{
    struct Snapshot
    {
        uint32 originalGuid;
        uint32 entry;
        uint32 count;
        uint32 price;
        uint32 timestamp;
        AscensionItemRecovery::Source source;
        std::string values;
        std::string text;
    };

    struct Pending
    {
        std::vector<Snapshot> snapshots;
        std::vector<uint32> returned;
    };

    std::atomic<bool> archiveEnabled{false};
    std::mutex pendingMutex;
    std::unordered_map<uint32, Pending> pending;

    bool Supports(Player* player, Item* item)
    {
        if (!archiveEnabled.load() || !player || !item || item->GetOwnerGUID() != player->GetGUID() ||
            item->GetValuesCount() != ITEM_END || item->IsWrapped() || item->IsRefundable() ||
            item->IsBOPTradable() || item->IsConjuredConsumable() ||
            item->GetUInt32Value(ITEM_FIELD_DURATION) || item->GetTemplate()->HasFlag(ITEM_FLAG_HAS_LOOT) ||
            LocalLevelScaling::InstanceTemplateFor(item, item->GetTemplate()) != item->GetTemplate())
            return false;
        for (uint8 slot = 0; slot < MAX_ENCHANTMENT_SLOT; ++slot)
            if (item->GetEnchantmentDuration(EnchantmentSlot(slot)))
                return false;
        return true;
    }

    bool Capture(Player* player, Item* item, uint32 count, AscensionItemRecovery::Source source, uint32 price)
    {
        if (!Supports(player, item) || !count || count > item->GetCount())
            return false;
        std::ostringstream values;
        for (uint16 field = OBJECT_END; field < ITEM_END; ++field)
            values << (field == ITEM_FIELD_STACK_COUNT ? count : item->GetUInt32Value(field)) << ' ';
        Snapshot snapshot{item->GetGUID().GetCounter(), item->GetEntry(), count, price,
            uint32(GameTime::GetGameTime().count()), source, values.str(), item->GetText()};
        std::lock_guard<std::mutex> lock(pendingMutex);
        pending[player->GetGUID().GetCounter()].snapshots.push_back(std::move(snapshot));
        return true;
    }

    void ForgetVendor(Player* player, Item* item)
    {
        std::lock_guard<std::mutex> lock(pendingMutex);
        pending[player->GetGUID().GetCounter()].returned.push_back(item->GetGUID().GetCounter());
    }

    void Flush(Player* player, CharacterDatabaseTransaction trans)
    {
        Pending work;
        {
            std::lock_guard<std::mutex> lock(pendingMutex);
            auto const found = pending.find(player->GetGUID().GetCounter());
            if (found == pending.end())
                return;
            work = std::move(found->second);
            pending.erase(found);
        }
        for (Snapshot const& snapshot : work.snapshots)
        {
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_EXACT_RECOVERY);
            stmt->SetData(0, player->GetGUID().GetCounter());
            stmt->SetData(1, snapshot.originalGuid);
            stmt->SetData(2, uint8(snapshot.source));
            stmt->SetData(3, snapshot.entry);
            stmt->SetData(4, snapshot.count);
            stmt->SetData(5, snapshot.price);
            stmt->SetData(6, snapshot.timestamp);
            stmt->SetData(7, snapshot.values);
            stmt->SetData(8, snapshot.text);
            trans->Append(stmt);
        }
        for (uint32 guid : work.returned)
        {
            auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_EXACT_RECOVERY_VENDOR);
            stmt->SetData(0, player->GetGUID().GetCounter());
            stmt->SetData(1, guid);
            trans->Append(stmt);
        }
        auto* prune = CharacterDatabase.GetPreparedStatement(CHAR_PRUNE_EXACT_RECOVERY);
        prune->SetData(0, player->GetGUID().GetCounter());
        prune->SetData(1, player->GetGUID().GetCounter());
        trans->Append(prune);
    }

    void Persist(Player* player)
    {
        {
            std::lock_guard<std::mutex> lock(pendingMutex);
            if (!pending.count(player->GetGUID().GetCounter()))
                return;
        }
        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        player->SaveInventoryAndGoldToDB(trans);
        CharacterDatabase.CommitTransaction(trans);
    }

    bool InBuyback(Player* player, uint32 guid)
    {
        for (uint32 slot = BUYBACK_SLOT_START; slot < BUYBACK_SLOT_END; ++slot)
            if (Item* item = player->GetItemFromBuyBackSlot(slot))
                if (item->GetGUID().GetCounter() == guid)
                    return true;
        return false;
    }
}

namespace ExactItemRecovery
{
void Configure()
{
    archiveEnabled.store(sConfigMgr->GetOption<bool>("ItemRecovery.Enable", true) &&
        sConfigMgr->GetOption<bool>("ItemRecovery.Archive.Enable", true));
}

void Initialize()
{
    Configure();
    AscensionItemRecovery::Capture = Capture;
    AscensionItemRecovery::ForgetVendor = ForgetVendor;
    AscensionItemRecovery::Flush = Flush;
    AscensionItemRecovery::Persist = Persist;
}

std::vector<Offer> Offers(Player* player, bool deleted)
{
    std::vector<Offer> offers;
    if (!archiveEnabled.load())
        return offers;
    auto* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_EXACT_RECOVERY_LIST);
    stmt->SetData(0, player->GetGUID().GetCounter());
    stmt->SetData(1, uint8(deleted ? AscensionItemRecovery::Source::Deleted : AscensionItemRecovery::Source::Vendored));
    if (PreparedQueryResult rows = CharacterDatabase.Query(stmt))
        do
        {
            Field* fields = rows->Fetch();
            Offer offer{fields[0].Get<uint64>(), fields[1].Get<uint32>(), fields[2].Get<uint32>(),
                fields[3].Get<uint32>(), fields[4].Get<uint32>(), fields[5].Get<uint32>()};
            if (sObjectMgr->GetItemTemplate(offer.entry) && !InBuyback(player, offer.originalGuid))
                offers.push_back(offer);
        } while (rows->NextRow());
    return offers;
}

char const* Restore(Player* player, uint64 id, bool deleted)
{
    if (!archiveEnabled.load() || !player->IsAlive() || player->GetTradeData() || player->IsBeingTeleportedFar())
        return "UNKNOWN";
    auto* query = CharacterDatabase.GetPreparedStatement(CHAR_SEL_EXACT_RECOVERY);
    query->SetData(0, id);
    query->SetData(1, player->GetGUID().GetCounter());
    query->SetData(2, uint8(deleted ? AscensionItemRecovery::Source::Deleted : AscensionItemRecovery::Source::Vendored));
    PreparedQueryResult row = CharacterDatabase.Query(query);
    if (!row)
        return "ALREADY_RECOVERED";
    Field* fields = row->Fetch();
    uint32 const originalGuid = fields[0].Get<uint32>();
    if (!deleted && (InBuyback(player, originalGuid) ||
        player->GetItemByGuid(ObjectGuid::Create<HighGuid::Item>(originalGuid))))
        return "ALREADY_RECOVERED";
    uint32 const entry = fields[1].Get<uint32>();
    uint32 const count = fields[2].Get<uint32>();
    uint32 const price = fields[3].Get<uint32>();
    ItemTemplate const* proto = sObjectMgr->GetItemTemplate(entry);
    if (!proto || !count || count > proto->GetMaxStackSize())
        return "BAD_ITEM";
    if (!player->HasEnoughMoney(price))
        return "NOT_ENOUGH_MONEY";
    std::unique_ptr<Item> item(Item::CreateItem(entry, count, player, true));
    if (!item || item->GetValuesCount() != ITEM_END)
        return "BAD_ITEM";
    std::istringstream values(fields[4].Get<std::string>());
    for (uint16 field = OBJECT_END; field < ITEM_END; ++field)
    {
        uint32 value = 0;
        if (!(values >> value))
            return "BAD_ITEM";
        item->SetUInt32Value(field, value);
    }
    values >> std::ws;
    if (!values.eof() || item->GetCount() != count || !Supports(player, item.get()))
        return "BAD_ITEM";
    item->SetGuidValue(ITEM_FIELD_CONTAINED, player->GetGUID());
    item->SetText(fields[5].Get<std::string>());
    ItemPosCountVec destinations;
    if (player->CanStoreItem(NULL_BAG, NULL_SLOT, destinations, item.get(), false) != EQUIP_ERR_OK)
        return "NOT_ENOUGH_SPACE";
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    MailDraft draft("Recovered item", "Your recovered item is enclosed.");
    item->SaveToDB(trans);
    draft.AddItem(item.release());
    auto staged = draft.StageMailTo(trans, player->GetGUID().GetCounter(), MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM));
    if (!staged)
    {
        draft.DiscardItems();
        return "UNKNOWN";
    }
    auto* receipt = CharacterDatabase.GetPreparedStatement(CHAR_INS_EXACT_RECOVERY_RECEIPT);
    receipt->SetData(0, id);
    receipt->SetData(1, player->GetGUID().GetCounter());
    receipt->SetData(2, staged->mailId);
    trans->Append(receipt);
    auto* remove = CharacterDatabase.GetPreparedStatement(CHAR_DEL_EXACT_RECOVERY);
    remove->SetData(0, id);
    remove->SetData(1, player->GetGUID().GetCounter());
    trans->Append(remove);
    player->ModifyMoney(-int32(price));
    player->SaveGoldToDB(trans);
    if (!CharacterDatabase.AsyncCommitTransaction(trans).m_future.get())
    {
        player->ModifyMoney(price);
        draft.DiscardItems();
        return "UNKNOWN";
    }
    draft.PublishStagedMail(*staged, player);
    return "OK";
}
}
