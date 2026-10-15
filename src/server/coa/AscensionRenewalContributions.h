/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_RENEWAL_CONTRIBUTIONS_H
#define ASCENSION_RENEWAL_CONTRIBUTIONS_H

#include <algorithm>
#include <cstdint>
#include <limits>
#include <vector>

namespace Ascension
{
class RenewalContributions
{
    struct Contribution
    {
        std::uint64_t Next;
        std::uint64_t Expires;
        std::uint32_t Period;
        std::int32_t Amount;
    };
    std::vector<Contribution> _contributions;

    static std::int32_t Clamp(std::uint64_t amount)
    {
        return static_cast<std::int32_t>(std::min<std::uint64_t>(amount,
            std::numeric_limits<std::int32_t>::max()));
    }

public:
    void Add(std::uint64_t now, std::int32_t amount, std::uint32_t duration, std::uint32_t period)
    {
        if (amount > 0 && duration && period)
            _contributions.push_back({now + period, now + duration, period, amount});
    }

    std::vector<std::int32_t> Advance(std::uint64_t now)
    {
        std::vector<std::int32_t> ticks;
        for (;;)
        {
            std::uint64_t next = std::numeric_limits<std::uint64_t>::max();
            for (auto const& entry : _contributions)
                if (entry.Next <= entry.Expires)
                    next = std::min(next, entry.Next);
            if (next > now)
                break;
            std::uint64_t amount = 0;
            for (auto& entry : _contributions)
                if (entry.Next == next && entry.Next <= entry.Expires)
                {
                    amount += entry.Amount;
                    entry.Next += entry.Period;
                }
            ticks.push_back(Clamp(amount));
        }
        std::erase_if(_contributions, [now](auto const& entry) { return entry.Expires <= now; });
        return ticks;
    }

    std::int32_t Amount() const
    {
        std::uint64_t amount = 0;
        for (auto const& entry : _contributions)
            amount += entry.Amount;
        return Clamp(amount);
    }

    std::int32_t Remaining(std::uint64_t now) const
    {
        std::uint64_t expires = now;
        for (auto const& entry : _contributions)
            expires = std::max(expires, entry.Expires);
        return Clamp(expires - now);
    }

    std::int32_t Delay(std::uint64_t now) const
    {
        std::uint64_t next = std::numeric_limits<std::uint64_t>::max();
        for (auto const& entry : _contributions)
            next = std::min(next, std::min(entry.Next, entry.Expires));
        return next > now ? std::max(1, Clamp(next - now)) : 1;
    }
};
}

#endif
