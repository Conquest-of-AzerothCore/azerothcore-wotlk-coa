#ifndef COA_PET_BATTLE_PROTOCOL_WIRE_TEXT_H
#define COA_PET_BATTLE_PROTOCOL_WIRE_TEXT_H

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace CoAPetBattles::Protocol
{
    std::string WireSafe(std::string_view text);
    std::string CutAtSentence(std::string const& text, int64_t room);
    std::string Cap(std::string_view text, int64_t room);
    std::string Integer(double value);
    std::vector<std::string> SplitStatusList(std::string const& text);
    std::optional<double> LuaNumberOf(std::string_view text);
}

#endif
