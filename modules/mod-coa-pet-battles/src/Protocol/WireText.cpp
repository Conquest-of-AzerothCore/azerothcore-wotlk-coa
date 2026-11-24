#include "WireText.h"
#include "Engine/Describe.h"
#include <algorithm>
#include <cmath>

namespace CoAPetBattles::Protocol
{
    std::string WireSafe(std::string_view text)
    {
        std::string safe(text);
        for (char& c : safe)
            if (c == '#' || c == '|' || c == '~' || c == ';')
                c = ' ';
        return safe;
    }

    std::string CutAtSentence(std::string const& text, int64_t room)
    {
        if (static_cast<int64_t>(text.size()) <= room)
            return text;
        std::string const cut = text.substr(0, static_cast<size_t>(std::max<int64_t>(room, 0)));
        size_t const dot = cut.rfind(". ");
        if (dot != std::string::npos && static_cast<double>(dot + 1) > static_cast<double>(room) * 0.5)
            return cut.substr(0, dot + 1);
        return cut.substr(0, static_cast<size_t>(std::max<int64_t>(room - 3, 0))) + "...";
    }

    std::string Cap(std::string_view text, int64_t room)
    {
        return CutAtSentence(WireSafe(text), room);
    }

    std::vector<std::string> SplitStatusList(std::string const& text)
    {
        constexpr size_t PartLimit = 190;
        std::vector<std::string> parts;
        std::string current;
        size_t start = 0;
        while (start <= text.size())
        {
            size_t const end = std::min(text.find(';', start), text.size());
            std::string const item = text.substr(start, end - start);
            start = end + 1;
            if (item.empty())
                continue;
            if (current.size() + item.size() + 1 > PartLimit && !current.empty())
            {
                parts.push_back(current);
                current.clear();
            }
            current += item + ";";
        }
        parts.push_back(current);
        return parts;
    }

    std::string Integer(double value)
    {
        return std::to_string(static_cast<int64_t>(value));
    }

    std::optional<double> LuaNumberOf(std::string_view text)
    {
        std::optional<double> const value = Engine::LuaToNumber(std::string(text));
        return value;
    }
}
