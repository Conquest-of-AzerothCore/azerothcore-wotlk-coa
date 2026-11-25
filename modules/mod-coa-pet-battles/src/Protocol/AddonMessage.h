#ifndef COA_PET_BATTLE_PROTOCOL_ADDON_MESSAGE_H
#define COA_PET_BATTLE_PROTOCOL_ADDON_MESSAGE_H

#include <cstddef>
#include <cstdint>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

namespace CoAPetBattles::Protocol
{
    inline constexpr char const* Prefix = "ACORE";
    inline constexpr size_t MaxSent = 240;
    inline constexpr size_t MaxReceived = 255;

    struct AddonMessage
    {
        std::string module;
        std::string action;
        std::string payload;
    };

    std::optional<AddonMessage> ParseAddonMessage(std::string_view text);
    std::optional<std::string> FormatAddonMessage(std::string_view module, std::string_view action,
        std::string_view payload);
    std::vector<std::string> Chunks(std::vector<std::string> const& parts);

    class AddonPeers
    {
    public:
        void Hello(uint64_t character, std::string_view payload);
        void Forget(uint64_t character);
        bool Has(uint64_t character, std::string_view addon) const;

    private:
        std::map<uint64_t, std::set<std::string, std::less<>>> _addons;
    };
}

#endif
