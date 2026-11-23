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

    struct ClientCache
    {
        std::uint32_t Item = 0;
        float ChancePct = 0.0f;
    };

    inline ClientCache ClientCacheState(ClientCache cache, bool coaLootMode)
    {
        if (coaLootMode)
            cache.ChancePct = 0.0f;
        return cache;
    }
}

#endif
