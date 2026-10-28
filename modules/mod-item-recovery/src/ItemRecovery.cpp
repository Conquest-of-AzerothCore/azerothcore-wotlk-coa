/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionCoAConfig.h"
#include "ExactItemRecovery.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <array>
#include <atomic>
#include <cstring>
#include <deque>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
    constexpr uint16 CMSG_QUERY_VENDORED_ITEM_RECOVERY = 0x05DE;
    constexpr uint16 SMSG_QUERY_VENDORED_ITEM_RECOVERY_RESULT = 0x05DF;
    constexpr uint16 CMSG_RECOVER_VENDORED_ITEM = 0x05E0;
    constexpr uint16 SMSG_RECOVER_VENDORED_ITEM_RESULT = 0x05E1;
    constexpr uint16 CMSG_QUERY_DELETED_ITEM_RECOVERY = 0x05E2;
    constexpr uint16 SMSG_QUERY_DELETED_ITEM_RECOVERY_RESULT = 0x05E3;
    constexpr uint16 CMSG_RECOVER_DELETED_ITEM = 0x05E4;
    constexpr uint16 SMSG_RECOVER_DELETED_ITEM_RESULT = 0x05E5;
    constexpr char RecoveryConfigKey[] = "CONFIG_RECOVERY_VENDORED_ITEM_ENABLED";
    constexpr char DeletedRecoveryConfigKey[] = "CONFIG_RECOVERY_DELETED_ITEM_ENABLED";
    constexpr std::size_t MaxQueuedRequests = 16;
    constexpr std::size_t RequestsPerUpdate = 4;

    struct Request
    {
        bool query = false;
        bool deleted = false;
        uint32 index = 0;
        std::string id;
    };

    struct Offer
    {
        uint32 slot;
        ObjectGuid guid;
        uint32 price;
        uint32 count;
        uint64 archiveId = 0;
        uint32 entry = 0;
        uint64 timestamp = 0;
        bool deleted = false;
    };

    struct AccountState
    {
        uint32 character = 0;
        std::deque<Request> requests;
        std::array<std::vector<Offer>, 2> offers;
    };

    std::atomic<bool> enabled{false};
    std::atomic<bool> archiveEnabled{false};
    std::atomic<bool> pending{false};
    std::mutex stateMutex;
    std::unordered_map<uint32, AccountState> states;

    void SendResult(Player* player, char const* suffix, bool deleted = false)
    {
        WorldPacket response(deleted ? SMSG_RECOVER_DELETED_ITEM_RESULT : SMSG_RECOVER_VENDORED_ITEM_RESULT, 64);
        response << (std::string(deleted ? "DELETED_ITEM_RECOVERY_" : "VENDORED_ITEM_RECOVERY_") + suffix);
        player->SendDirectMessage(&response);
    }

    std::string OfferId(Offer const& offer)
    {
        return offer.archiveId ? "snapshot:" + std::to_string(offer.archiveId) : offer.guid.ToString();
    }

    void SendOffers(Player* player, bool deleted = false)
    {
        std::vector<Offer> offers;
        if (!deleted)
            for (uint32 slot = BUYBACK_SLOT_START; slot < BUYBACK_SLOT_END; ++slot)
                if (Item* item = player->GetItemFromBuyBackSlot(slot))
                {
                    uint32 const stamp = player->GetUInt32Value(
                        PLAYER_FIELD_BUYBACK_TIMESTAMP_1 + slot - BUYBACK_SLOT_START);
                    offers.push_back({slot, item->GetGUID(),
                        player->GetUInt32Value(PLAYER_FIELD_BUYBACK_PRICE_1 + slot - BUYBACK_SLOT_START),
                        item->GetCount(), 0, item->GetEntry(), uint64(player->m_logintime + stamp - 30 * HOUR), false});
                }
        for (ExactItemRecovery::Offer const& archived : ExactItemRecovery::Offers(player, deleted))
        {
            if (offers.size() == 500)
                break;
            offers.push_back({0, ObjectGuid::Empty, archived.price, archived.count, archived.id,
                archived.entry, archived.timestamp, deleted});
        }
        WorldPacket response(deleted ? SMSG_QUERY_DELETED_ITEM_RECOVERY_RESULT :
            SMSG_QUERY_VENDORED_ITEM_RECOVERY_RESULT, 4 + offers.size() * 128);
        response << uint32(offers.size());
        for (Offer const& offer : offers)
        {
            response << OfferId(offer) << offer.entry << offer.count;
            response << std::string() << uint32(0) << uint8(0);
            response << offer.timestamp << uint64(offer.price) << uint32(0) << uint32(0);
            WorldPacket itemQuery(CMSG_ITEM_QUERY_SINGLE, sizeof(uint32));
            itemQuery << offer.entry;
            player->GetSession()->HandleItemQuerySingleOpcode(itemQuery);
        }
        {
            std::lock_guard<std::mutex> lock(stateMutex);
            AccountState& state = states[player->GetSession()->GetAccountId()];
            state.character = player->GetGUID().GetCounter();
            state.offers[deleted ? 1 : 0] = std::move(offers);
        }
        player->SendDirectMessage(&response);
    }

    void Recover(Player* player, Request const& request)
    {
        auto result = [player, &request](char const* suffix)
        {
            SendResult(player, suffix, request.deleted);
            SendOffers(player, request.deleted);
        };
        Offer offer{};
        bool found = false;
        {
            std::lock_guard<std::mutex> lock(stateMutex);
            auto const itr = states.find(player->GetSession()->GetAccountId());
            if (itr != states.end() && itr->second.character == player->GetGUID().GetCounter())
            {
                std::vector<Offer> const& offers = itr->second.offers[request.deleted ? 1 : 0];
                if (request.index < offers.size())
                {
                    offer = offers[request.index];
                    found = true;
                }
            }
        }

        if (!found)
            return result("OUT_OF_RANGE");
        if (request.id != OfferId(offer) || request.deleted != offer.deleted)
            return result("ID_MISMATCH");
        if (offer.archiveId)
        {
            result(ExactItemRecovery::Restore(player, offer.archiveId, request.deleted));
            return;
        }

        Item* item = player->GetItemFromBuyBackSlot(offer.slot);
        if (!item || item->GetGUID() != offer.guid || item->GetCount() != offer.count)
            return result("ALREADY_RECOVERED");

        uint32 const price = player->GetUInt32Value(PLAYER_FIELD_BUYBACK_PRICE_1 + offer.slot - BUYBACK_SLOT_START);
        if (price != offer.price)
            return result("ID_MISMATCH");
        if (!player->IsAlive() || player->GetTradeData() || player->IsBeingTeleportedFar())
            return result("UNKNOWN");
        if (!player->HasEnoughMoney(price))
            return result("NOT_ENOUGH_MONEY");

        ItemPosCountVec destinations;
        if (player->CanStoreItem(NULL_BAG, NULL_SLOT, destinations, item, false) != EQUIP_ERR_OK)
            return result("NOT_ENOUGH_SPACE");

        // The same item instance native buyback returns: enchantments, random properties, charges,
        // binding and durability are preserved.
        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        if (sWorld->getBoolConfig(CONFIG_ITEMDELETE_VENDOR))
        {
            CharacterDatabasePreparedStatement* statement =
                CharacterDatabase.GetPreparedStatement(CHAR_DEL_RECOVERY_ITEM);
            statement->SetData(0, player->GetGUID().GetCounter());
            statement->SetData(1, item->GetEntry());
            statement->SetData(2, item->GetCount());
            transaction->Append(statement);
        }

        player->ModifyMoney(-int32(price));
        player->RemoveItemFromBuyBackSlot(offer.slot, false);
        player->ItemAddedQuestCheck(item->GetEntry(), item->GetCount());
        Item* stored = player->StoreItem(destinations, item, true);
        player->SendNewItem(stored, offer.count, false, false);
        player->SaveToDB(transaction, false, false);
        CharacterDatabase.CommitTransaction(transaction);
        result("OK");
    }

    bool ReadRecoverRequest(WorldPacket const& packet, Request& request)
    {
        if (packet.size() < 6 || packet.size() > 128)
            return false;

        uint8 const* first = packet.contents() + sizeof(uint32);
        uint8 const* last = packet.contents() + packet.size() - 1;
        if (std::memchr(first, '\0', packet.size() - sizeof(uint32)) != last)
            return false;

        WorldPacket input(packet);
        input >> request.index >> request.id;
        return true;
    }
}

class ItemRecoveryWorld final : public WorldScript
{
public:
    ItemRecoveryWorld() : WorldScript("ItemRecoveryWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        enabled.store(sConfigMgr->GetOption<bool>("ItemRecovery.Enable", true));
        archiveEnabled.store(enabled.load() && sConfigMgr->GetOption<bool>("ItemRecovery.Archive.Enable", true));
        ExactItemRecovery::Configure();
    }
};

class ItemRecoveryNetwork final : public ServerScript
{
public:
    ItemRecoveryNetwork() : ServerScript("ItemRecoveryNetwork", { SERVERHOOK_CAN_PACKET_RECEIVE_EARLY }) { }

    bool CanPacketReceiveEarly(WorldSession* session, WorldPacket const& packet) override
    {
        uint16 const opcode = packet.GetOpcode();
        if ((opcode != CMSG_QUERY_VENDORED_ITEM_RECOVERY && opcode != CMSG_RECOVER_VENDORED_ITEM &&
            opcode != CMSG_QUERY_DELETED_ITEM_RECOVERY && opcode != CMSG_RECOVER_DELETED_ITEM)
            || !session || !enabled.load())
            return true;

        if (session->IsBot())
            return false;

        Request request;
        request.query = opcode == CMSG_QUERY_VENDORED_ITEM_RECOVERY || opcode == CMSG_QUERY_DELETED_ITEM_RECOVERY;
        request.deleted = opcode == CMSG_QUERY_DELETED_ITEM_RECOVERY || opcode == CMSG_RECOVER_DELETED_ITEM;
        if (request.query ? !packet.empty() : !ReadRecoverRequest(packet, request))
            return false;

        std::lock_guard<std::mutex> lock(stateMutex);
        AccountState& state = states[session->GetAccountId()];
        if (state.requests.size() < MaxQueuedRequests)
            state.requests.push_back(std::move(request));
        pending.store(true);
        return false;
    }
};

class ItemRecoveryPlayer final : public PlayerScript
{
public:
    ItemRecoveryPlayer() : PlayerScript("ItemRecoveryPlayer",
        { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE }) { }

    void OnPlayerLogin(Player* player) override
    {
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetSession()->GetAccountId());
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard<std::mutex> lock(stateMutex);
        states.erase(player->GetSession()->GetAccountId());
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!pending.load() || !enabled.load() || !player->IsInWorld() || player->GetSession()->IsBot())
            return;

        std::deque<Request> requests;
        {
            std::lock_guard<std::mutex> lock(stateMutex);
            auto const itr = states.find(player->GetSession()->GetAccountId());
            if (itr != states.end())
                for (std::size_t count = 0; count < RequestsPerUpdate && !itr->second.requests.empty(); ++count)
                {
                    requests.push_back(std::move(itr->second.requests.front()));
                    itr->second.requests.pop_front();
                }

            bool more = false;
            for (auto const& [account, state] : states)
                more |= !state.requests.empty();
            pending.store(more);
        }

        for (Request const& request : requests)
        {
            if (request.query)
                SendOffers(player, request.deleted);
            else
                Recover(player, request);
        }
    }
};

void AddItemRecoveryScripts()
{
    ExactItemRecovery::Initialize();
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        config.Booleans.emplace_back(RecoveryConfigKey, enabled.load());
        config.Booleans.emplace_back(DeletedRecoveryConfigKey, archiveEnabled.load());
    });
    new ItemRecoveryWorld();
    new ItemRecoveryNetwork();
    new ItemRecoveryPlayer();
}
