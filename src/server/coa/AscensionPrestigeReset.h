#ifndef ASCENSION_PRESTIGE_RESET_H
#define ASCENSION_PRESTIGE_RESET_H

#include <cstdint>
#include <string>

class Player;

namespace AscensionPrestigeReset
{
struct Plan
{
    std::uint32_t Build = 0;
    std::uint32_t Enchants = 0;
};

struct Result
{
    std::uint32_t Abilities = 0;
    std::uint32_t Enchants = 0;
};

struct Handler
{
    bool (*Applies)(Player const*);
    bool (*Prepare)(Player*, Plan&, std::string&);
    bool (*Reset)(Player*, Plan const&, Result&, std::string&);
};

inline Handler const* Area52 = nullptr;
}

#endif
