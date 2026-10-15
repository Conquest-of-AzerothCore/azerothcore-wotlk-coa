/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Battleground.h"
#include "BattlegroundMgr.h"
#include "Chat.h"
#include "Config.h"
#include "CreatureScript.h"
#include "DBCStores.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptedGossip.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
    enum WarGamesGossip : uint32
    {
        MenuTeri = 900031,
        MenuInvitation = 900032,
        TextInvitation = 900032,
        TextExplanation = 900033,
        SenderTeri = 1,
        ActionExplain = 100,
        ActionBack = 101,
        ActionCancel = 102,
        ActionAccept = 103,
        ActionDecline = 104
    };

    struct ArenaChoice
    {
        char const* Name;
        BattlegroundTypeId Type;
    };

    // Labels and order of the original War Games destination list. BATTLEGROUND_TYPE_NONE marks a
    // destination that has not been restored; another map is never substituted for it.
    constexpr std::array<ArenaChoice, 15> ArenaChoices = {{
        {"Random Arena", BATTLEGROUND_TYPE_NONE}, {"Nagrand Arena", BATTLEGROUND_NA},
        {"Blades Edge Arena", BATTLEGROUND_BE}, {"Ruins of Lordaeron Arena", BATTLEGROUND_RL},
        {"The Tiger's Peak Arena", BATTLEGROUND_TYPE_NONE}, {"Guardian's Hall", BATTLEGROUND_TYPE_NONE},
        {"Ashamane's Fall", BATTLEGROUND_TYPE_NONE}, {"Tol'viron Arena", BATTLEGROUND_TYPE_NONE},
        {"Coliseum of Past Echoes", BATTLEGROUND_TYPE_NONE}, {"Maldraxxus Coliseum", BATTLEGROUND_TYPE_NONE},
        {"Nagrand Arena HD", BATTLEGROUND_TYPE_NONE}, {"Blade's Edge Arena HD", BATTLEGROUND_TYPE_NONE},
        {"The Twisting Nether", BATTLEGROUND_TYPE_NONE}, {"Imperial Arena Of Thakraj", BATTLEGROUND_TYPE_NONE},
        {"Blackrook Hold", BATTLEGROUND_TYPE_NONE}
    }};

    struct PendingInvitation
    {
        ObjectGuid Challenger;
        std::string ChallengerName;
        uint64 Token;
        uint32 Choice;
        bool Shown = false;
    };

    struct AcceptedInvitation
    {
        ObjectGuid Opponent;
        uint64 Token;
    };

    std::atomic<bool> enabled{true};

    // Leaders answer from their own map threads, which update in parallel.
    std::mutex invitationMutex;
    std::unordered_map<ObjectGuid, PendingInvitation> pendingInvitations;
    std::atomic<bool> unshownInvitations{false};

    // Matches are created on the world thread, like every other battleground instance.
    std::mutex acceptedMutex;
    std::vector<AcceptedInvitation> acceptedInvitations;

    void Notice(Player* player, char const* text)
    {
        if (player && player->GetSession())
            ChatHandler(player->GetSession()).SendSysMessage(text);
    }

    void CancelPending(Player* player)
    {
        std::lock_guard<std::mutex> lock(invitationMutex);
        for (auto itr = pendingInvitations.begin(); itr != pendingInvitations.end();)
        {
            if (itr->first == player->GetGUID() || itr->second.Challenger == player->GetGUID())
            {
                sBattlegroundMgr->CancelWargame(player, itr->second.Token);
                itr = pendingInvitations.erase(itr);
            }
            else
                ++itr;
        }

        unshownInvitations.store(std::any_of(pendingInvitations.begin(), pendingInvitations.end(),
            [](auto const& entry) { return !entry.second.Shown; }));
    }

    bool AbortMatch(uint32 instance)
    {
        Battleground* battleground = sBattlegroundMgr->GetBattleground(instance, BATTLEGROUND_TYPE_NONE);
        if (!battleground || !battleground->IsWargame())
            return false;

        battleground->SetStatus(STATUS_WAIT_LEAVE);
        battleground->SetEndTime(0);
        return true;
    }

    void ReleasePlayer(Player* player)
    {
        player->SetBattlegroundId(0, BATTLEGROUND_TYPE_NONE, PLAYER_MAX_BATTLEGROUND_QUEUES, false, false,
            TEAM_NEUTRAL);
    }

    uint32 StartAcceptedMatch(Player* opponent, uint64 invitation)
    {
        std::optional<WargameAdmission> admission = sBattlegroundMgr->AcceptWargame(opponent, invitation);
        if (!admission)
            return 0;

        Battleground* original = sBattlegroundMgr->GetBattlegroundTemplate(admission->Type);
        if (!original)
            return 0;

        PvPDifficultyEntry const* bracket = GetBattlegroundBracketByLevel(original->GetMapId(), opponent->GetLevel());
        Battleground* battleground = sBattlegroundMgr->CreateNewWargame(admission->Type, bracket);
        if (!battleground)
            return 0;

        battleground->StartBattleground();

        for (uint8 side = 0; side < PVP_TEAMS_COUNT; ++side)
        {
            for (ObjectGuid guid : admission->Rosters[side])
            {
                Player* player = ObjectAccessor::FindPlayer(guid);
                if (!player)
                {
                    AbortMatch(battleground->GetInstanceID());
                    return 0;
                }

                TeamId const team = static_cast<TeamId>(side);
                player->SetEntryPoint();
                player->SetBattlegroundId(battleground->GetInstanceID(), battleground->GetBgTypeID(), 0, true,
                    false, team);

                // The destination map must exist before any transfer can be cancelled: a worldport
                // acknowledgement cannot create an instance that is already leaving.
                if (!sMapMgr->CreateMap(battleground->GetMapId(), player))
                {
                    ReleasePlayer(player);
                    AbortMatch(battleground->GetInstanceID());
                    return 0;
                }

                battleground->IncreaseInvitedCount(team);
                if (!sBattlegroundMgr->SendToBattleground(player, battleground->GetInstanceID(), admission->Type))
                {
                    battleground->DecreaseInvitedCount(team);
                    ReleasePlayer(player);
                    AbortMatch(battleground->GetInstanceID());
                    return 0;
                }

                WorldPacket status;
                sBattlegroundMgr->BuildBattlegroundStatusPacket(&status, battleground, 0, STATUS_IN_PROGRESS, 0,
                    battleground->GetStartTime(), battleground->GetArenaType(), team, false);
                player->SendDirectMessage(&status);
            }
        }

        return battleground->GetInstanceID();
    }

    std::optional<PendingInvitation> TakeUnshownInvitation(Player* player)
    {
        std::lock_guard<std::mutex> lock(invitationMutex);
        auto const found = pendingInvitations.find(player->GetGUID());
        if (found == pendingInvitations.end() || found->second.Shown)
            return std::nullopt;

        found->second.Shown = true;
        unshownInvitations.store(std::any_of(pendingInvitations.begin(), pendingInvitations.end(),
            [](auto const& entry) { return !entry.second.Shown; }));
        return found->second;
    }

    std::optional<PendingInvitation> FindInvitation(Player* player)
    {
        std::lock_guard<std::mutex> lock(invitationMutex);
        auto const found = pendingInvitations.find(player->GetGUID());
        return found == pendingInvitations.end() ? std::nullopt : std::optional<PendingInvitation>(found->second);
    }

    void ShowInvitation(Player* player, PendingInvitation const& invitation)
    {
        ClearGossipMenuFor(player);
        player->PlayerTalkClass->GetGossipMenu().SetMenuId(MenuInvitation);
        std::string const arena = ArenaChoices[invitation.Choice].Name;
        std::string const prompt = invitation.ChallengerName + " challenges you and your group to a Wargame in "
            + arena + ".\n\nReady to face them? Accept to enter the match.";
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Accept the challenge: " + invitation.ChallengerName + " - " + arena,
            SenderTeri, ActionAccept, prompt, 0, false);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Decline the challenge.", SenderTeri, ActionDecline);
        SendGossipMenuFor(player, TextInvitation, player->GetGUID());
    }
}

class npc_war_games_teri_glozilk final : public CreatureScript
{
public:
    npc_war_games_teri_glozilk() : CreatureScript("npc_coa_teri_glozilk") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!enabled.load())
            return false;

        creature->SetFacingToObject(player);
        if (std::optional<PendingInvitation> const incoming = FindInvitation(player))
        {
            ShowInvitation(player, *incoming);
            return true;
        }

        ClearGossipMenuFor(player);
        player->PlayerTalkClass->GetGossipMenu().SetMenuId(MenuTeri);
        for (uint32 i = 0; i < ArenaChoices.size(); ++i)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, ArenaChoices[i].Name, SenderTeri, i, "", 0, true);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Tell me about Wargames.", SenderTeri, ActionExplain);

        bool challenging = false;
        {
            std::lock_guard<std::mutex> lock(invitationMutex);
            challenging = std::any_of(pendingInvitations.begin(), pendingInvitations.end(),
                [player](auto const& entry) { return entry.second.Challenger == player->GetGUID(); });
        }
        if (challenging)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Cancel my pending challenge.", SenderTeri, ActionCancel);

        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
    {
        if (sender != SenderTeri)
            return true;

        if (action == ActionExplain)
        {
            ClearGossipMenuFor(player);
            player->PlayerTalkClass->GetGossipMenu().SetMenuId(MenuTeri);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Choose an arena.", SenderTeri, ActionBack);
            SendGossipMenuFor(player, TextExplanation, creature);
        }
        else if (action == ActionBack || action == ActionCancel)
        {
            if (action == ActionCancel)
                CancelPending(player);
            OnGossipHello(player, creature);
        }

        return true;
    }

    bool OnGossipSelectCode(Player* player, Creature* /*creature*/, uint32 sender, uint32 action,
        char const* code) override
    {
        if (sender != SenderTeri || action >= ArenaChoices.size() || !code)
            return true;

        if (ArenaChoices[action].Type == BATTLEGROUND_TYPE_NONE)
        {
            Notice(player, "That battlefield isn't ready for a match just yet.");
            return true;
        }

        std::string name(code);
        Player* opponent = normalizePlayerName(name) ? ObjectAccessor::FindPlayerByName(name) : nullptr;
        uint64 const token = sBattlegroundMgr->RequestWargame(player, opponent, ArenaChoices[action].Type,
            std::chrono::steady_clock::time_point::max());
        if (!token)
        {
            Notice(player, "I can't arrange that match right now. Make sure both leaders and their groups "
                "are ready, then try again.");
            return true;
        }

        {
            std::lock_guard<std::mutex> lock(invitationMutex);
            pendingInvitations[opponent->GetGUID()] = { player->GetGUID(), player->GetName(), token, action };
            unshownInvitations.store(true);
        }

        CloseGossipMenuFor(player);
        Notice(player, "The challenge is on its way. Let's see if they're ready to face you!");
        return true;
    }
};

class WarGamesConsent final : public PlayerScript
{
public:
    WarGamesConsent() : PlayerScript("WarGamesConsent",
        { PLAYERHOOK_ON_GOSSIP_SELECT, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE }) { }

    void OnPlayerGossipSelect(Player* player, uint32 menu, uint32 sender, uint32 action) override
    {
        if (menu != MenuInvitation || sender != SenderTeri || (action != ActionAccept && action != ActionDecline))
            return;

        PendingInvitation invitation{};
        {
            std::lock_guard<std::mutex> lock(invitationMutex);
            auto const found = pendingInvitations.find(player->GetGUID());
            if (found == pendingInvitations.end())
                return;

            invitation = found->second;
            pendingInvitations.erase(found);
        }

        CloseGossipMenuFor(player);
        ClearGossipMenuFor(player);

        if (action == ActionDecline)
        {
            sBattlegroundMgr->CancelWargame(player, invitation.Token);
            Notice(ObjectAccessor::FindPlayer(invitation.Challenger),
                "They've passed on this one. Find another rival and we'll try again.");
            return;
        }

        std::lock_guard<std::mutex> lock(acceptedMutex);
        acceptedInvitations.push_back({ player->GetGUID(), invitation.Token });
    }

    void OnPlayerUpdate(Player* player, uint32 /*diff*/) override
    {
        if (!unshownInvitations.load() || !player->IsInWorld())
            return;

        if (std::optional<PendingInvitation> const invitation = TakeUnshownInvitation(player))
            ShowInvitation(player, *invitation);
    }

    void OnPlayerLogout(Player* player) override
    {
        CancelPending(player);
    }
};

class WarGamesWorld final : public WorldScript
{
public:
    WarGamesWorld() : WorldScript("WarGamesWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_UPDATE }) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        enabled.store(sConfigMgr->GetOption<bool>("WarGames.Enable", true));
    }

    void OnUpdate(uint32 /*diff*/) override
    {
        std::vector<AcceptedInvitation> accepted;
        {
            std::lock_guard<std::mutex> lock(acceptedMutex);
            accepted.swap(acceptedInvitations);
        }

        for (AcceptedInvitation const& invitation : accepted)
        {
            Player* opponent = ObjectAccessor::FindPlayer(invitation.Opponent);
            if (opponent && !StartAcceptedMatch(opponent, invitation.Token))
                Notice(opponent, "That challenge is no longer available.");
        }
    }
};

void AddWarGamesScripts()
{
    new npc_war_games_teri_glozilk();
    new WarGamesConsent();
    new WarGamesWorld();
}
