/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AccountScript.h"
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
    struct PendingHello
    {
        WorldSession const* Session;
        uint8 ClientMaxSlots;
    };

    std::unordered_map<uint32, PendingHello> PendingHellos;
    std::atomic<bool> HasPendingHellos{ false };

    bool HandleHello(WorldSession* session, WorldPacket const& packet)
    {
        std::optional<QuestLogExtended::Hello> const hello = QuestLogExtended::ParseHello(packet);
        if (!session || !hello)
            return true;

        std::lock_guard<std::mutex> lock(PendingHelloMutex);
        PendingHellos[session->GetAccountId()] = { session, hello->ClientMaxSlots };
        HasPendingHellos.store(true, std::memory_order_release);
        return true;
    }

    std::optional<uint8> TakePendingHello(WorldSession const* session)
    {
        if (!HasPendingHellos.load(std::memory_order_acquire))
            return std::nullopt;

        std::lock_guard<std::mutex> lock(PendingHelloMutex);
        auto const found = PendingHellos.find(session->GetAccountId());
        if (found == PendingHellos.end())
            return std::nullopt;

        PendingHello const pending = found->second;
        PendingHellos.erase(found);
        HasPendingHellos.store(!PendingHellos.empty(), std::memory_order_release);
        if (pending.Session != session)
            return std::nullopt;

        return pending.ClientMaxSlots;
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

            if (std::optional<uint8> const clientMaxSlots = TakePendingHello(session))
            {
                player->SetQuestLogExtended(true, *clientMaxSlots);
                player->SendQuestLogExtendedSnapshot();
            }
        }
    };

    class AscensionQuestLogExtendedAccount final : public AccountScript
    {
    public:
        AscensionQuestLogExtendedAccount()
            : AccountScript("ascension_quest_log_extended_account", {ACCOUNTHOOK_ON_ACCOUNT_LOGIN})
        {
        }

        void OnAccountLogin(uint32 accountId) override
        {
            ForgetPendingHello(accountId);
        }
    };
}

void AddSC_AscensionQuestLogExtended()
{
    AscensionCompatOpcodes::Claim(QuestLogExtended::HelloOpcode, &HandleHello);
    new AscensionQuestLogExtendedPlayer();
    new AscensionQuestLogExtendedAccount();
}
