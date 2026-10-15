/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionCoAConfig.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

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
    constexpr char RecoveryConfigKey[] = "CONFIG_RECOVERY_VENDORED_ITEM_ENABLED";
    constexpr std::size_t MaxQueuedRequests = 16;
    constexpr std::size_t RequestsPerUpdate = 4;

    struct Request
    {
        bool query = false;
        uint32 index = 0;
        std::string id;
    };

    struct Offer
    {
        uint32 slot;
        ObjectGuid guid;
        uint32 price;
        uint32 count;
    };

    struct AccountState
    {
        uint32 character = 0;
        std::deque<Request> requests;
        std::vector<Offer> offers;
    };

    std::atomic<bool> enabled{false};
    std::atomic<bool> pending{false};
    std::mutex stateMutex;
    std::unordered_map<uint32, AccountState> states;

    void SendResult(Player* player, char const* suffix)
    {
        WorldPacket response(SMSG_RECOVER_VENDORED_ITEM_RESULT, 64);
        response << (std::string("VENDORED_ITEM_RECOVERY_") + suffix);
        player->SendDirectMessage(&response);
    }

    void SendOffers(Player* player)
    {
        std::vector<Offer> offers;
        for (uint32 slot = BUYBACK_SLOT_START; slot < BUYBACK_SLOT_END; ++slot)
            if (Item* item = player->GetItemFromBuyBackSlot(slot))
                offers.push_back({slot, item->GetGUID(),
                    player->GetUInt32Value(PLAYER_FIELD_BUYBACK_PRICE_1 + slot - BUYBACK_SLOT_START),
                    item->GetCount()});

        // Extensions.dll 0x10301A70: a common item-recovery record followed by two empty cost maps.
        WorldPacket response(SMSG_QUERY_VENDORED_ITEM_RECOVERY_RESULT, 4 + offers.size() * 128);
        response << uint32(offers.size());
        for (Offer const& offer : offers)
        {
            Item* item = player->GetItemFromBuyBackSlot(offer.slot);
            uint32 const stamp = player->GetUInt32Value(
                PLAYER_FIELD_BUYBACK_TIMESTAMP_1 + offer.slot - BUYBACK_SLOT_START);
            uint64 const soldAt = uint64(player->m_logintime + stamp - 30 * HOUR);
            response << offer.guid.ToString() << item->GetEntry() << offer.count;
            response << std::string() << uint32(0) << uint8(0);
            response << soldAt << uint64(offer.price) << uint32(0) << uint32(0);

            WorldPacket itemQuery(CMSG_ITEM_QUERY_SINGLE, sizeof(uint32));
            itemQuery << item->GetEntry();
            player->GetSession()->HandleItemQuerySingleOpcode(itemQuery);
        }

        {
            std::lock_guard<std::mutex> lock(stateMutex);
            AccountState& state = states[player->GetSession()->GetAccountId()];
            state.character = player->GetGUID().GetCounter();
            state.offers = std::move(offers);
        }
        player->SendDirectMessage(&response);
    }

    void Recover(Player* player, Request const& request)
    {
        Offer offer{};
        bool found = false;
        {
            std::lock_guard<std::mutex> lock(stateMutex);
            auto const itr = states.find(player->GetSession()->GetAccountId());
            if (itr != states.end() && itr->second.character == player->GetGUID().GetCounter()
                && request.index < itr->second.offers.size())
            {
                offer = itr->second.offers[request.index];
                found = true;
            }
        }

        if (!found)
            return SendResult(player, "OUT_OF_RANGE");
        if (request.id != offer.guid.ToString())
            return SendResult(player, "ID_MISMATCH");

        Item* item = player->GetItemFromBuyBackSlot(offer.slot);
        if (!item || item->GetGUID() != offer.guid || item->GetCount() != offer.count)
            return SendResult(player, "ALREADY_RECOVERED");

        uint32 const price = player->GetUInt32Value(PLAYER_FIELD_BUYBACK_PRICE_1 + offer.slot - BUYBACK_SLOT_START);
        if (price != offer.price)
            return SendResult(player, "ID_MISMATCH");
        if (!player->IsAlive() || player->GetTradeData() || player->IsBeingTeleportedFar())
            return SendResult(player, "UNKNOWN");
        if (!player->HasEnoughMoney(price))
            return SendResult(player, "NOT_ENOUGH_MONEY");

        ItemPosCountVec destinations;
        if (player->CanStoreItem(NULL_BAG, NULL_SLOT, destinations, item, false) != EQUIP_ERR_OK)
            return SendResult(player, "NOT_ENOUGH_SPACE");

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
        SendResult(player, "OK");
        SendOffers(player);
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
    }
};

class ItemRecoveryNetwork final : public ServerScript
{
public:
    ItemRecoveryNetwork() : ServerScript("ItemRecoveryNetwork", { SERVERHOOK_CAN_PACKET_RECEIVE_EARLY }) { }

    bool CanPacketReceiveEarly(WorldSession* session, WorldPacket const& packet) override
    {
        uint16 const opcode = packet.GetOpcode();
        if ((opcode != CMSG_QUERY_VENDORED_ITEM_RECOVERY && opcode != CMSG_RECOVER_VENDORED_ITEM)
            || !session || !enabled.load())
            return true;

        if (session->IsBot())
            return false;

        Request request;
        request.query = opcode == CMSG_QUERY_VENDORED_ITEM_RECOVERY;
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
                SendOffers(player);
            else
                Recover(player, request);
        }
    }
};

void AddItemRecoveryScripts()
{
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        if (enabled.load())
            config.Booleans.emplace_back(RecoveryConfigKey, true);
    });
    new ItemRecoveryWorld();
    new ItemRecoveryNetwork();
    new ItemRecoveryPlayer();
}
