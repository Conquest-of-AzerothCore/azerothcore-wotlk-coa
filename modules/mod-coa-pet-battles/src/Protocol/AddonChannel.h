#ifndef COA_PET_BATTLE_PROTOCOL_ADDON_CHANNEL_H
#define COA_PET_BATTLE_PROTOCOL_ADDON_CHANNEL_H

#include "AddonMessage.h"
#include <functional>
#include <mutex>
#include <string>
#include <utility>

class Player;

namespace CoAPetBattles::Protocol
{
    class AddonChannel
    {
    public:
        using Handler = std::function<void(Player*, std::string const&)>;

        static AddonChannel* instance();

        bool Receive(Player* player, std::string const& message);
        void Update(uint32_t diff);
        void On(std::string const& module, std::string const& action, Handler handler);
        bool Send(Player* player, std::string_view module, std::string_view action, std::string_view payload);
        void SendChunks(Player* player, std::string_view module, std::string_view action,
            std::vector<std::string> const& parts);
        bool Has(Player* player, std::string_view addon) const;
        void Forget(Player* player);

    private:
        AddonChannel();

        std::mutex _lock;
        std::vector<std::pair<uint64_t, std::string>> _queue;
        std::map<std::string, Handler> _handlers;
        AddonPeers _peers;
        uint32_t _sinceStart = 0;
        bool _askedWho = false;
    };
}

#define sAddonChannel CoAPetBattles::Protocol::AddonChannel::instance()

#endif
