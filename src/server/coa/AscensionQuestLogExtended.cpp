/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCompatOpcodes.h"
#include "Player.h"
#include "PlayerScript.h"
#include "QuestLogExtended.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <atomic>
#include <mutex>
#include <optional>
#include <unordered_map>

namespace
{
    std::mutex PendingHelloMutex;
    std::unordered_map<uint32, uint8> PendingHellos;
    std::atomic<bool> HasPendingHellos{ false };

    bool HandleHello(WorldSession* session, WorldPacket const& packet)
    {
        std::optional<QuestLogExtended::Hello> const hello = QuestLogExtended::ParseHello(packet);
        if (!session || !hello)
            return true;

        std::lock_guard<std::mutex> lock(PendingHelloMutex);
        PendingHellos[session->GetAccountId()] = hello->ClientMaxSlots;
        HasPendingHellos.store(true, std::memory_order_release);
        return true;
    }

    std::optional<uint8> TakePendingHello(uint32 accountId)
    {
        if (!HasPendingHellos.load(std::memory_order_acquire))
            return std::nullopt;

        std::lock_guard<std::mutex> lock(PendingHelloMutex);
        auto const found = PendingHellos.find(accountId);
        if (found == PendingHellos.end())
            return std::nullopt;

        uint8 const clientMaxSlots = found->second;
        PendingHellos.erase(found);
        HasPendingHellos.store(!PendingHellos.empty(), std::memory_order_release);
        return clientMaxSlots;
    }

    void ForgetPendingHello(uint32 accountId)
    {
        std::lock_guard<std::mutex> lock(PendingHelloMutex);
        PendingHellos.erase(accountId);
        HasPendingHellos.store(!PendingHellos.empty(), std::memory_order_release);
    }

    class AscensionQuestLogExtendedPlayer final : public PlayerScript
    {
    public:
        AscensionQuestLogExtendedPlayer()
            : PlayerScript("ascension_quest_log_extended",
                {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE})
        {
        }

        void OnPlayerLogin(Player* player) override
        {
            player->SetQuestLogExtended(false);
        }

        void OnPlayerLogout(Player* player) override
        {
            if (WorldSession* session = player->GetSession())
                ForgetPendingHello(session->GetAccountId());
        }

        void OnPlayerUpdate(Player* player, uint32) override
        {
            WorldSession* session = player->GetSession();
            if (!session || !player->IsInWorld())
                return;

            if (std::optional<uint8> const clientMaxSlots = TakePendingHello(session->GetAccountId()))
            {
                player->SetQuestLogExtended(true, *clientMaxSlots);
                player->SendQuestLogExtendedSnapshot();
            }
        }
    };
}

void AddSC_AscensionQuestLogExtended()
{
    AscensionCompatOpcodes::Claim(QuestLogExtended::HelloOpcode, &HandleHello);
    new AscensionQuestLogExtendedPlayer();
}
