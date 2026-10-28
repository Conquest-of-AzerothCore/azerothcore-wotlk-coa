/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AccountMgr.h"
#include "Base64.h"
#include "Chat.h"
#include "CoAProbeRelay.h"
#include "Config.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Timer.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <mutex>

namespace CoAProbeRelay
{
using namespace Acore::ChatCommands;

namespace
{
std::mutex relayMutex;
ReplyBook book;
bool enabled = false;
std::string accountPrefix = "COALAB";

Player* FindLabPlayer(ChatHandler* handler, std::string name)
{
    if (!enabled)
    {
        handler->SendErrorMessage("probe relay disabled", false);
        return nullptr;
    }
    std::string const requested = name;
    Player* player = normalizePlayerName(name) ? ObjectAccessor::FindPlayerByName(name) : nullptr;
    if (!player)
    {
        handler->SendErrorMessage(requested + " is not online", false);
        return nullptr;
    }
    std::string account;
    if (!AccountMgr::GetName(player->GetSession()->GetAccountId(), account) || !IsLabAccount(account, accountPrefix))
    {
        handler->SendErrorMessage(requested + " is not a lab account", false);
        return nullptr;
    }
    return player;
}
}

class ProbeRelayConfiguration final : public WorldScript
{
public:
    ProbeRelayConfiguration() : WorldScript("coa_probe_relay_configuration", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool) override
    {
        std::lock_guard lock(relayMutex);
        enabled = sConfigMgr->GetOption<bool>("CoA.ProbeRelay.Enable", false);
        accountPrefix = sConfigMgr->GetOption<std::string>("CoA.ProbeRelay.AccountPrefix", "COALAB");
    }
};

class ProbeRelayPlayers final : public PlayerScript
{
public:
    ProbeRelayPlayers() : PlayerScript("coa_probe_relay_players",
        {PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT, PLAYERHOOK_ON_LOGOUT}) { }

    bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 language, std::string& message,
        Player* receiver) override
    {
        if (type != CHAT_MSG_WHISPER || language != LANG_ADDON || receiver != player
            || !message.starts_with(std::string(Prefix) + "\t"))
            return true;
        std::lock_guard lock(relayMutex);
        if (!enabled)
            return true;
        if (std::optional<ReplyChunk> chunk = ParseReplyChunk(message))
            book.Accept(player->GetGUID().GetRawValue(), *chunk, getMSTime());
        return false;
    }

    void OnPlayerLogout(Player* player) override
    {
        std::lock_guard lock(relayMutex);
        book.Forget(player->GetGUID().GetRawValue());
    }
};

class ProbeRelayCommands final : public CommandScript
{
public:
    ProbeRelayCommands() : CommandScript("coa_probe_relay_commands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable children =
        {
            {"send", HandleSend, SEC_ADMINISTRATOR, Console::Yes},
            {"result", HandleResult, SEC_ADMINISTRATOR, Console::Yes}
        };
        static ChatCommandTable commands = {{"labprobe", children}};
        return commands;
    }

    static bool HandleSend(ChatHandler* handler, std::string character, std::string req, Tail line)
    {
        std::lock_guard lock(relayMutex);
        Player* player = FindLabPlayer(handler, character);
        if (!player)
            return false;
        std::optional<std::string> message = RequestMessage(req, line);
        if (!message)
        {
            handler->SendErrorMessage("not a read-only probe request", false);
            return false;
        }
        book.Arm(player->GetGUID().GetRawValue(), req, getMSTime());
        WorldPacket packet;
        ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player, *message);
        player->SendDirectMessage(&packet);
        handler->PSendSysMessage("sent {}", req);
        return true;
    }

    static bool HandleResult(ChatHandler* handler, std::string character, std::string req)
    {
        std::lock_guard lock(relayMutex);
        Player* player = FindLabPlayer(handler, character);
        if (!player)
            return false;
        ReplyStatus status = book.Status(player->GetGUID().GetRawValue(), req, getMSTime());
        if (status.state == ReplyState::Complete)
            handler->PSendSysMessage("complete {}",
                Acore::Encoding::Base64::Encode(std::vector<uint8>(status.body.begin(), status.body.end())));
        else if (status.state == ReplyState::Pending)
            handler->PSendSysMessage("pending {}/{}", status.received, status.total);
        else
            handler->SendSysMessage("unknown");
        return true;
    }
};
}

void AddSC_CoAProbeRelay()
{
    new CoAProbeRelay::ProbeRelayConfiguration();
    new CoAProbeRelay::ProbeRelayPlayers();
    new CoAProbeRelay::ProbeRelayCommands();
}
