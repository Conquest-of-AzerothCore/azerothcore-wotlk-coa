#ifndef COA_PET_BATTLE_PROTOCOL_JOURNAL_MESSAGES_H
#define COA_PET_BATTLE_PROTOCOL_JOURNAL_MESSAGES_H

#include "Engine/Catalog.h"
#include "Store/Journal.h"
#include <functional>
#include <string>
#include <string_view>

namespace CoAPetBattles::Protocol
{
    struct JournalReply
    {
        std::function<void(std::string_view module, std::string_view action, std::string const& payload)> send;
        std::function<void()> syncCompanions;
        uint32_t now = 0;
    };

    std::string PetMessage(Engine::Catalog const& catalog, Store::Journal const& journal, Store::OwnedPet const& pet,
        uint32_t now);
    void SendJournal(Engine::Catalog const& catalog, Store::Journal const& journal, JournalReply const& reply);
    bool HandleJournalMessage(Engine::Catalog const& catalog, Store::Journal& journal, std::string const& action,
        std::string const& payload, JournalReply const& reply);
}

#endif
