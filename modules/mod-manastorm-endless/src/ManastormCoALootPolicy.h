#ifndef MANASTORM_COA_LOOT_POLICY_H
#define MANASTORM_COA_LOOT_POLICY_H

#include <cstdint>

namespace ManastormCoALoot
{
    constexpr std::uint32_t TokenItem = 975001;

    struct Window
    {
        std::uint32_t Start = 0;
        std::uint32_t End = 0;
        std::uint32_t Earned = 0;
    };

    inline Window CurrentWindow(Window saved, std::uint32_t now)
    {
        if (saved.Start && now < saved.End)
            return saved;
        return {};
    }
}

#endif
