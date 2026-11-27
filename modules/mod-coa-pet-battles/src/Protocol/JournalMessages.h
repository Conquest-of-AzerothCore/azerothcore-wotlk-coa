#ifndef COA_PET_BATTLE_PROTOCOL_JOURNAL_MESSAGES_H
#define COA_PET_BATTLE_PROTOCOL_JOURNAL_MESSAGES_H

#include "Engine/Catalog.h"
#include "Store/Journal.h"
#include <functional>
#include <optional>
#include <string>
#include <string_view>

namespace CoAPetBattles::Protocol
{
    struct JournalReply
    {
        std::function<void(std::string_view module, std::string_view action, std::string const& payload)> send;
        std::function<void()> syncCompanions;
        std::function<std::optional<uint8_t>(uint32_t item)> foodLevel;
        std::function<bool(uint32_t item)> hasItem;
        std::function<void(uint32_t item)> takeItem;
        std::function<bool()> inBattle;
        std::function<bool()> releaseBlocked;
        std::function<void(uint32_t)> released;
        std::function<void(uint32_t petId, uint32_t steps, uint64_t stepMs)> fedRefresh;
        std::function<void(uint32_t petId)> summon;
        std::function<void()> dismiss;
        std::function<uint32_t()> follower;
        std::function<std::optional<uint32_t>()> prime;
        uint32_t now = 0;
        bool ownedIds = false;
    };

    std::string TeamMessage(Store::Journal const& journal, uint8_t team, bool ownedIds = false);
    std::string PetMessage(Engine::Catalog const& catalog, Store::Journal const& journal, Store::OwnedPet const& pet,
        uint32_t now, bool ownedIds = false);
    void SendJournal(Engine::Catalog const& catalog, Store::Journal const& journal, JournalReply const& reply);
    bool HandleJournalMessage(Engine::Catalog const& catalog, Store::Journal& journal, std::string const& action,
        std::string const& payload, JournalReply const& reply);
}

#endif
