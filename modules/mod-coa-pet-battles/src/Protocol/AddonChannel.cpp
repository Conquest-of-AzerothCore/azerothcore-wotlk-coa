#include "AddonChannel.h"
#include "Chat.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "WorldPacket.h"
#include "WorldSession.h"

namespace CoAPetBattles::Protocol
{
    namespace
    {
        constexpr uint32_t WhoDelayMs = 3000;

        bool Human(Player* player)
        {
            return player && player->GetSession() && !player->GetSession()->IsBot();
        }
    }

    AddonChannel* AddonChannel::instance()
    {
        static AddonChannel channel;
        return &channel;
    }

    AddonChannel::AddonChannel()
    {
        On("core", "hello", [this](Player* player, std::string const& payload)
        {
            _peers.Hello(player->GetGUID().GetCounter(), payload);
        });
        On("core", "ping", [this](Player* player, std::string const& payload)
        {
            Send(player, "core", "pong", payload);
        });
    }

    bool AddonChannel::Receive(Player* player, std::string const& message)
    {
        std::string const prefix = std::string(Prefix) + "\t";
        if (message.compare(0, prefix.size(), prefix) != 0)
            return false;
        if (Human(player))
        {
            std::lock_guard<std::mutex> guard(_lock);
            _queue.emplace_back(player->GetGUID().GetCounter(), message.substr(prefix.size()));
        }
        return true;
    }

    void AddonChannel::Update(uint32_t diff)
    {
        if (!_askedWho)
        {
            _sinceStart += diff;
            if (_sinceStart >= WhoDelayMs)
            {
                _askedWho = true;
                for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
                    if (Human(player) && player->IsInWorld())
                        Send(player, "core", "who", "");
            }
        }

        std::vector<std::pair<uint64_t, std::string>> queued;
        {
            std::lock_guard<std::mutex> guard(_lock);
            queued.swap(_queue);
        }
        for (auto const& [character, text] : queued)
        {
            Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(
                static_cast<ObjectGuid::LowType>(character)));
            std::optional<AddonMessage> message = ParseAddonMessage(text);
            if (!Human(player) || !message)
                continue;
            auto const handler = _handlers.find(message->module + "|" + message->action);
            if (handler != _handlers.end())
                handler->second(player, message->payload);
        }
    }

    void AddonChannel::On(std::string const& module, std::string const& action, Handler handler)
    {
        _handlers[module + "|" + action] = std::move(handler);
    }

    bool AddonChannel::Send(Player* player, std::string_view module, std::string_view action,
        std::string_view payload)
    {
        if (!Human(player))
            return false;
        std::optional<std::string> text = FormatAddonMessage(module, action, payload);
        if (!text)
        {
            LOG_ERROR("module", "Addon message {}|{} is too long ({} characters)", module, action,
                module.size() + action.size() + payload.size() + 2);
            return false;
        }
        WorldPacket packet;
        ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player,
            std::string(Prefix) + "\t" + *text);
        player->SendDirectMessage(&packet);
        return true;
    }

    void AddonChannel::SendChunks(Player* player, std::string_view module, std::string_view action,
        std::vector<std::string> const& parts)
    {
        for (std::string const& chunk : Chunks(parts))
            Send(player, module, action, chunk);
    }

    bool AddonChannel::Has(Player* player, std::string_view addon) const
    {
        return player && _peers.Has(player->GetGUID().GetCounter(), addon);
    }

    void AddonChannel::Forget(Player* player)
    {
        if (player)
            _peers.Forget(player->GetGUID().GetCounter());
    }
}
