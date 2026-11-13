#include "CoAEconomyLog.h"

#include "AscensionBazaarTokenReserve.h"
#include "AuctionHouseMgr.h"
#include "CharacterCache.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "Mail.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "Tokenize.h"
#include "WorldSession.h"

#include <array>
#include <atomic>
#include <cmath>
#include <mutex>
#include <unordered_map>
#include <utility>
#include <vector>

namespace
{
    std::atomic<bool> s_enabled{false};
    std::atomic<uint32> s_keepDays{90};

    constexpr std::array<std::pair<std::string_view, CoAEconomyEvent>, 24> EventNames{{
        {"vanity_store_buy", CoAEconomyEvent::VanityStoreBuy},
        {"vanity_collect", CoAEconomyEvent::VanityCollect},
        {"vendor_buy", CoAEconomyEvent::VendorBuy},
        {"vendor_sell", CoAEconomyEvent::VendorSell},
        {"vendor_buyback", CoAEconomyEvent::VendorBuyback},
        {"bazaar_rotation_buy", CoAEconomyEvent::BazaarRotationBuy},
        {"heirloom_token_buy", CoAEconomyEvent::HeirloomTokenBuy},
        {"cache_open", CoAEconomyEvent::CacheOpen},
        {"ah_list", CoAEconomyEvent::AhList},
        {"ah_cancel", CoAEconomyEvent::AhCancel},
        {"ah_bid", CoAEconomyEvent::AhBid},
        {"ah_buyout", CoAEconomyEvent::AhBuyout},
        {"ah_sold", CoAEconomyEvent::AhSold},
        {"ah_expired", CoAEconomyEvent::AhExpired},
        {"trade", CoAEconomyEvent::Trade},
        {"mail_send", CoAEconomyEvent::MailSend},
        {"mail_take", CoAEconomyEvent::MailTake},
        {"system_mail", CoAEconomyEvent::SystemMail},
        {"tokens_earned", CoAEconomyEvent::TokensEarned},
        {"tokens_spent", CoAEconomyEvent::TokensSpent},
        {"item_destroy", CoAEconomyEvent::ItemDestroy},
        {"highrisk_drop", CoAEconomyEvent::HighRiskDrop},
        {"highrisk_claim", CoAEconomyEvent::HighRiskClaim},
        {"reward", CoAEconomyEvent::Reward},
    }};

    struct PendingRow
    {
        uint32 account = 0;
        uint16 map = 0;
        uint16 zone = 0;
        CoAEconomyRow row;
    };

    std::mutex s_queueLock;
    std::unordered_map<ObjectGuid::LowType, std::vector<PendingRow>> s_queue;

    uint32 Now()
    {
        return uint32(GameTime::GetGameTime().count());
    }

    bool Logs(Player const* player)
    {
        return CoAEconomyLog::Enabled() && player && player->GetSession() && !player->GetSession()->IsBot();
    }

    uint32 AccountOf(ObjectGuid::LowType guid)
    {
        if (!guid)
            return 0;
        if (Player* player = ObjectAccessor::FindPlayerByLowGUID(guid))
            return player->GetSession()->GetAccountId();
        return sCharacterCache->GetCharacterAccountIdByGuid(ObjectGuid::Create<HighGuid::Player>(guid));
    }

    void WriteFor(CharacterDatabaseTransaction trans, ObjectGuid::LowType guid, CoAEconomyRow const& row)
    {
        if (!CoAEconomyLog::Enabled() || !guid)
            return;
        if (Player* player = ObjectAccessor::FindPlayerByLowGUID(guid))
        {
            if (player->GetSession()->IsBot())
                return;
            CoAEconomyLog::Write(trans, player->GetSession()->GetAccountId(), guid, uint16(player->GetMapId()),
                uint16(player->GetZoneId()), row);
            return;
        }
        CoAEconomyLog::Write(trans, AccountOf(guid), guid, 0, 0, row);
    }

    CoAEconomyRow MailTakeRow(Mail const* mail)
    {
        CoAEconomyRow row;
        row.event = CoAEconomyEvent::MailTake;
        row.source = mail->messageID;
        if (mail->messageType == MAIL_NORMAL && mail->sender)
        {
            row.otherGuid = mail->sender;
            row.otherAccount = AccountOf(mail->sender);
        }
        return row;
    }
}

bool CoAEconomyLog::Enabled()
{
    return s_enabled.load(std::memory_order_relaxed);
}

bool CoAEconomyLog::SetEnabled(bool enabled)
{
    return s_enabled.exchange(enabled);
}

std::optional<CoAEconomyEvent> CoAEconomyLog::EventByName(std::string_view name)
{
    for (auto const& [eventName, event] : EventNames)
        if (eventName == name)
            return event;
    return std::nullopt;
}

void CoAEconomyLog::Queue(Player* player, CoAEconomyRow const& row)
{
    if (!Logs(player))
        return;
    PendingRow pending;
    pending.account = player->GetSession()->GetAccountId();
    pending.map = uint16(player->GetMapId());
    pending.zone = uint16(player->GetZoneId());
    pending.row = row;
    if (!pending.row.time)
        pending.row.time = Now();
    std::lock_guard<std::mutex> guard(s_queueLock);
    s_queue[player->GetGUID().GetCounter()].push_back(pending);
}

void CoAEconomyLog::Write(CharacterDatabaseTransaction trans, uint32 account, uint32 guid, uint16 map, uint16 zone,
    CoAEconomyRow const& row)
{
    trans->Append("INSERT INTO coa_economy_log (time, account, guid, event, item_entry, item_guid, item_count, gold, tokens, "
        "cost_item, cost_count, other_account, other_guid, source, map, zone) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {})",
        row.time ? row.time : Now(), account, guid, uint32(row.event), row.itemEntry, row.itemGuid, row.itemCount, row.gold,
        row.tokens, row.costItem, row.costCount, row.otherAccount, row.otherGuid, row.source, map, zone);
}

void CoAEconomyLog::FlushQueue(Player* player, CharacterDatabaseTransaction trans)
{
    std::vector<PendingRow> rows;
    {
        std::lock_guard<std::mutex> guard(s_queueLock);
        auto const found = s_queue.find(player->GetGUID().GetCounter());
        if (found == s_queue.end())
            return;
        rows = std::move(found->second);
        s_queue.erase(found);
    }
    for (PendingRow const& pending : rows)
        Write(trans, pending.account, player->GetGUID().GetCounter(), pending.map, pending.zone, pending.row);
}

void CoAEconomyLog::CacheItem(Player* player, uint32 cacheEntry, Item const* item, uint32 count)
{
    if (!item)
        return;
    CoAEconomyRow row;
    row.event = CoAEconomyEvent::CacheOpen;
    row.itemEntry = item->GetEntry();
    row.itemGuid = item->GetGUID().GetCounter();
    row.itemCount = count;
    row.source = cacheEntry;
    Queue(player, row);
    if (row.itemEntry == AscensionBazaarTokenReserve::TOKEN_ITEM)
        AddTokensEarned(player, int32(count), CoATokenSource::Cache);
}

void CoAEconomyLog::AddTokensEarned(Player* player, int32 tokens, CoATokenSource source)
{
    if (!tokens || !Logs(player))
        return;
    std::lock_guard<std::mutex> guard(s_queueLock);
    std::vector<PendingRow>& rows = s_queue[player->GetGUID().GetCounter()];
    for (PendingRow& pending : rows)
        if (pending.row.event == CoAEconomyEvent::TokensEarned && pending.row.source == uint32(source))
        {
            pending.row.tokens += tokens;
            return;
        }
    PendingRow pending;
    pending.account = player->GetSession()->GetAccountId();
    pending.map = uint16(player->GetMapId());
    pending.zone = uint16(player->GetZoneId());
    pending.row.event = CoAEconomyEvent::TokensEarned;
    pending.row.tokens = tokens;
    pending.row.source = uint32(source);
    pending.row.time = Now();
    rows.push_back(pending);
}

namespace
{
    class CoAEconomyLogPlayer : public PlayerScript
    {
    public:
        CoAEconomyLogPlayer() : PlayerScript("CoAEconomyLogPlayer", { PLAYERHOOK_ON_SAVE_INVENTORY, PLAYERHOOK_ON_LOGOUT,
            PLAYERHOOK_ON_AFTER_DESTROY_ITEM, PLAYERHOOK_ON_AFTER_STORE_OR_EQUIP_NEW_ITEM, PLAYERHOOK_ON_AFTER_SELL_ITEM,
            PLAYERHOOK_ON_AFTER_BUY_BACK_ITEM, PLAYERHOOK_ON_AFTER_TAKE_MAIL_ITEM, PLAYERHOOK_ON_AFTER_TAKE_MAIL_MONEY,
            PLAYERHOOK_ON_AFTER_TRADE_ITEM, PLAYERHOOK_ON_AFTER_TRADE_MONEY, PLAYERHOOK_ON_AFTER_PLACE_AUCTION_BID,
            PLAYERHOOK_ON_LOOT_ITEM, PLAYERHOOK_ON_QUEST_REWARD_ITEM }) { }

        void OnPlayerAfterPlaceAuctionBid(Player* player, AuctionEntry const* auction, uint32 paid, bool buyout,
            CharacterDatabaseTransaction trans) override
        {
            CoAEconomyRow row;
            row.event = buyout ? CoAEconomyEvent::AhBuyout : CoAEconomyEvent::AhBid;
            row.itemEntry = auction->item_template;
            row.itemGuid = auction->item_guid.GetCounter();
            row.itemCount = auction->itemCount;
            row.gold = -int64(paid);
            row.source = auction->Id;
            row.otherGuid = auction->owner.GetCounter();
            row.otherAccount = AccountOf(row.otherGuid);
            WriteFor(trans, player->GetGUID().GetCounter(), row);
        }

        void OnPlayerAfterTradeItem(Player* receiver, Player* giver, uint32 itemEntry, ObjectGuid::LowType itemGuid,
            uint32 count) override
        {
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::Trade;
            row.itemEntry = itemEntry;
            row.itemGuid = itemGuid;
            row.itemCount = count;
            row.otherGuid = giver->GetGUID().GetCounter();
            row.otherAccount = giver->GetSession()->GetAccountId();
            CoAEconomyLog::Queue(receiver, row);
        }

        void OnPlayerAfterTradeMoney(Player* receiver, Player* giver, uint32 money) override
        {
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::Trade;
            row.gold = int64(money);
            row.otherGuid = giver->GetGUID().GetCounter();
            row.otherAccount = giver->GetSession()->GetAccountId();
            CoAEconomyLog::Queue(receiver, row);
        }

        void OnPlayerAfterTakeMailItem(Player* player, Mail const* mail, uint32 itemEntry, ObjectGuid::LowType itemGuid,
            uint32 count, CharacterDatabaseTransaction trans) override
        {
            CoAEconomyRow row = MailTakeRow(mail);
            row.itemEntry = itemEntry;
            row.itemGuid = itemGuid;
            row.itemCount = count;
            WriteFor(trans, player->GetGUID().GetCounter(), row);
        }

        void OnPlayerAfterTakeMailMoney(Player* player, Mail const* mail, uint32 money, CharacterDatabaseTransaction trans) override
        {
            if (!money)
                return;
            CoAEconomyRow row = MailTakeRow(mail);
            row.gold = int64(money);
            WriteFor(trans, player->GetGUID().GetCounter(), row);
        }

        void OnPlayerQuestRewardItem(Player* player, Item* item, uint32 count) override
        {
            if (item && item->GetEntry() == AscensionBazaarTokenReserve::TOKEN_ITEM)
                CoAEconomyLog::AddTokensEarned(player, int32(count), CoATokenSource::Quest);
        }

        void OnPlayerLootItem(Player* player, Item* item, uint32 count, ObjectGuid lootguid) override
        {
            if (!item)
                return;
            if (lootguid.IsItem())
            {
                Item const* container = player->GetItemByGuid(lootguid);
                if (container && container->GetTemplate()->HasFlag(ITEM_FLAG_HAS_LOOT))
                    CoAEconomyLog::CacheItem(player, container->GetEntry(), item, count);
                return;
            }
            if (item->GetEntry() != AscensionBazaarTokenReserve::TOKEN_ITEM || !lootguid.IsCreatureOrVehicle())
                return;
            CoATokenSource source = CoATokenSource::Kill;
            if (Creature const* creature = ObjectAccessor::GetCreature(*player, lootguid))
                if (creature->IsDungeonBoss())
                    source = creature->GetMap()->IsRaid() ? CoATokenSource::RaidBoss : CoATokenSource::DungeonBoss;
            CoAEconomyLog::AddTokensEarned(player, int32(count), source);
        }

        void OnPlayerAfterStoreOrEquipNewItem(Player* player, uint32, Item* item, uint8 count, uint8, uint8,
            ItemTemplate const* proto, Creature* vendor, VendorItem const* crItem, bool) override
        {
            if (!item || !proto || !crItem || !vendor)
                return;
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::VendorBuy;
            row.itemEntry = proto->ItemId;
            row.itemGuid = item->GetGUID().GetCounter();
            row.itemCount = proto->BuyCount * count;
            uint32 const list = player->GetSession()->GetCurrentVendor();
            row.source = list ? list : vendor->GetEntry();
            if (crItem->IsGoldRequired(proto) && proto->BuyPrice > 0)
            {
                uint32 price = proto->BuyPrice * count;
                price = uint32(std::floor(price * player->GetReputationPriceDiscount(vendor)));
                row.gold = -int64(price);
            }
            if (crItem->ExtendedCost)
                if (ItemExtendedCostEntry const* cost = sItemExtendedCostStore.LookupEntry(crItem->ExtendedCost))
                    for (uint8 i = 0; i < MAX_ITEM_EXTENDED_COST_REQUIREMENTS; ++i)
                    {
                        if (!cost->reqitem[i])
                            continue;
                        uint32 const paid = cost->reqitemcount[i] * count;
                        if (cost->reqitem[i] == AscensionBazaarTokenReserve::TOKEN_ITEM)
                            row.tokens -= int32(paid);
                        else if (!row.costItem)
                        {
                            row.costItem = cost->reqitem[i];
                            row.costCount = paid;
                        }
                    }
            CoAEconomyLog::Queue(player, row);
        }

        void OnPlayerAfterSellItem(Player* player, uint32 itemEntry, ObjectGuid::LowType itemGuid, uint32 count, uint32 money,
            Creature* vendor) override
        {
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::VendorSell;
            row.itemEntry = itemEntry;
            row.itemGuid = itemGuid;
            row.itemCount = count;
            row.gold = int64(money);
            row.source = vendor ? vendor->GetEntry() : 0;
            CoAEconomyLog::Queue(player, row);
        }

        void OnPlayerAfterBuyBackItem(Player* player, uint32 itemEntry, ObjectGuid::LowType itemGuid, uint32 count, uint32 price,
            Creature* vendor) override
        {
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::VendorBuyback;
            row.itemEntry = itemEntry;
            row.itemGuid = itemGuid;
            row.itemCount = count;
            row.gold = -int64(price);
            row.source = vendor ? vendor->GetEntry() : 0;
            CoAEconomyLog::Queue(player, row);
        }

        void OnPlayerSaveInventory(Player* player, CharacterDatabaseTransaction trans) override
        {
            CoAEconomyLog::FlushQueue(player, trans);
        }

        void OnPlayerLogout(Player* player) override
        {
            std::lock_guard<std::mutex> guard(s_queueLock);
            s_queue.erase(player->GetGUID().GetCounter());
        }

        void OnPlayerAfterDestroyItem(Player* player, uint32 itemEntry, ObjectGuid::LowType itemGuid, uint32 count) override
        {
            ItemTemplate const* proto = sObjectMgr->GetItemTemplate(itemEntry);
            if (!proto || proto->Quality < ITEM_QUALITY_RARE)
                return;
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::ItemDestroy;
            row.itemEntry = itemEntry;
            row.itemGuid = itemGuid;
            row.itemCount = count;
            CoAEconomyLog::Queue(player, row);
        }
    };

    class CoAEconomyLogMail : public MailScript
    {
    public:
        CoAEconomyLogMail() : MailScript("CoAEconomyLogMail", { MAILHOOK_ON_AFTER_MAIL_DRAFT_APPEND_ROWS }) { }

        void OnAfterMailDraftAppendRows(MailDraft const* draft, StagedMail const& staged, CharacterDatabaseTransaction trans) override
        {
            if (!CoAEconomyLog::Enabled())
                return;
            MailMessageType const type = staged.sender.GetMailMessageType();
            if (type == MAIL_AUCTION)
            {
                AuctionMail(draft, staged, trans);
                return;
            }
            bool const fromPlayer = type == MAIL_NORMAL && staged.sender.GetSenderId();
            ObjectGuid::LowType const owner = fromPlayer ? staged.sender.GetSenderId() : staged.receiverGuidLow;
            CoAEconomyRow row;
            row.event = fromPlayer ? CoAEconomyEvent::MailSend : CoAEconomyEvent::SystemMail;
            row.source = staged.mailId;
            if (fromPlayer)
            {
                row.otherGuid = staged.receiverGuidLow;
                row.otherAccount = AccountOf(staged.receiverGuidLow);
            }
            for (auto const& [itemGuid, item] : draft->GetItems())
            {
                row.itemEntry = item->GetEntry();
                row.itemGuid = item->GetGUID().GetCounter();
                row.itemCount = item->GetCount();
                WriteFor(trans, owner, row);
            }
            if (draft->GetMoney())
            {
                row.itemEntry = 0;
                row.itemGuid = 0;
                row.itemCount = 0;
                row.gold = fromPlayer ? -int64(draft->GetMoney()) : int64(draft->GetMoney());
                WriteFor(trans, owner, row);
            }
        }

    private:
        static void AuctionMail(MailDraft const* draft, StagedMail const& staged, CharacterDatabaseTransaction trans)
        {
            std::vector<std::string_view> const parts = Acore::Tokenize(draft->GetSubject(), ':', true);
            if (parts.size() < 5)
                return;
            std::optional<uint32> const response = Acore::StringTo<uint32>(parts[2]);
            std::optional<uint32> const auctionId = Acore::StringTo<uint32>(parts[3]);
            if (!response || !auctionId)
                return;
            AuctionHouseObject* house = sAuctionMgr->GetAuctionsMapByHouseId(AuctionHouseId(staged.sender.GetSenderId()));
            AuctionEntry const* auction = house ? house->GetAuction(*auctionId) : nullptr;
            if (!auction)
                return;
            CoAEconomyRow row;
            row.itemEntry = auction->item_template;
            row.itemGuid = auction->item_guid.GetCounter();
            row.itemCount = auction->itemCount;
            row.source = auction->Id;
            switch (*response)
            {
                case AUCTION_OUTBIDDED:
                case AUCTION_CANCELLED_TO_BIDDER:
                    row.event = CoAEconomyEvent::AhBid;
                    row.gold = int64(draft->GetMoney());
                    row.otherGuid = auction->owner.GetCounter();
                    break;
                case AUCTION_SUCCESSFUL:
                    row.event = CoAEconomyEvent::AhSold;
                    row.gold = int64(draft->GetMoney());
                    row.otherGuid = auction->bidder.GetCounter();
                    break;
                case AUCTION_EXPIRED:
                    row.event = CoAEconomyEvent::AhExpired;
                    break;
                case AUCTION_CANCELED:
                    row.event = CoAEconomyEvent::AhCancel;
                    if (auction->bidder)
                        row.gold = -int64(auction->GetAuctionCut());
                    break;
                default:
                    return;
            }
            row.otherAccount = AccountOf(row.otherGuid);
            WriteFor(trans, staged.receiverGuidLow, row);
        }
    };

    class CoAEconomyLogAuction : public AuctionHouseScript
    {
    public:
        CoAEconomyLogAuction() : AuctionHouseScript("CoAEconomyLogAuction", { AUCTIONHOUSEHOOK_ON_AUCTION_ADD }) { }

        void OnAuctionAdd(AuctionHouseObject*, AuctionEntry* auction) override
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(auction->owner);
            if (!owner)
                return;
            CoAEconomyRow row;
            row.event = CoAEconomyEvent::AhList;
            row.itemEntry = auction->item_template;
            row.itemGuid = auction->item_guid.GetCounter();
            row.itemCount = auction->itemCount;
            row.gold = -int64(auction->deposit);
            row.source = auction->Id;
            CoAEconomyLog::Queue(owner, row);
        }
    };

    class CoAEconomyLogWorld : public WorldScript
    {
    public:
        CoAEconomyLogWorld() : WorldScript("CoAEconomyLogWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

        void OnAfterConfigLoad(bool) override
        {
            s_enabled = sConfigMgr->GetOption<bool>("CoA.EconomyLog.Enable", false);
            s_keepDays = sConfigMgr->GetOption<uint32>("CoA.EconomyLog.KeepDays", 90);
        }
    };
}

void AddSC_CoAEconomyLog()
{
    new CoAEconomyLogPlayer();
    new CoAEconomyLogMail();
    new CoAEconomyLogAuction();
    new CoAEconomyLogWorld();
}
