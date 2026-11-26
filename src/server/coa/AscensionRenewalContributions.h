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
    bool _active = false;
    std::uint64_t _next = 0;
    std::uint64_t _expires = 0;
    std::uint32_t _period = 0;
    std::int32_t _amount = 0;

    static std::int32_t Clamp(std::uint64_t amount)
    {
        return static_cast<std::int32_t>(std::min<std::uint64_t>(amount,
            std::numeric_limits<std::int32_t>::max()));
    }

    static std::uint64_t SaturatingMul(std::uint64_t a, std::uint64_t b)
    {
        return a && b > std::numeric_limits<std::uint64_t>::max() / a
            ? std::numeric_limits<std::uint64_t>::max()
            : a * b;
    }

    static std::uint64_t SaturatingAdd(std::uint64_t a, std::uint64_t b)
    {
        return b > std::numeric_limits<std::uint64_t>::max() - a
            ? std::numeric_limits<std::uint64_t>::max()
            : a + b;
    }

    std::uint64_t RemainingTicks() const
    {
        if (!_active || !_period || _next > _expires)
            return 0;
        return 1 + (_expires - _next) / _period;
    }

public:
    void Add(std::uint64_t now, std::int32_t amount, std::uint32_t duration, std::uint32_t period)
    {
        if (amount <= 0 || !duration || !period)
            return;

        if (_active && _expires <= now)
        {
            _active = false;
            _amount = 0;
        }

        std::uint64_t remainingPool = _active ? SaturatingMul(std::uint64_t(_amount), RemainingTicks()) : 0;
        std::uint64_t newTicks = duration / period;
        std::uint64_t newPool = SaturatingMul(std::uint64_t(amount), newTicks);
        std::uint64_t expires = now + duration;

        if (!_active)
        {
            _active = true;
            _next = now + period;
            _expires = expires;
        }
        else
        {
            _expires = std::max(_expires, expires);
            if (_next > now + period)
                _next = now + period;
        }
        _period = period;

        std::uint64_t totalTicks = RemainingTicks();
        _amount = totalTicks ? Clamp(SaturatingAdd(remainingPool, newPool) / totalTicks) : 0;
    }

    std::vector<std::int32_t> Advance(std::uint64_t now)
    {
        std::vector<std::int32_t> ticks;
        if (!_active)
            return ticks;
        while (_period && _next <= _expires && _next <= now)
        {
            if (_amount > 0)
                ticks.push_back(_amount);
            _next += _period;
        }
        if (_expires <= now)
        {
            _active = false;
            _amount = 0;
        }
        return ticks;
    }

    std::int32_t Amount() const
    {
        return _active ? _amount : 0;
    }

    std::int32_t Remaining(std::uint64_t now) const
    {
        return _active && _expires > now ? Clamp(_expires - now) : 0;
    }

    std::int32_t Delay(std::uint64_t now) const
    {
        if (!_active)
            return 1;
        std::uint64_t next = std::min(_next, _expires);
        return next > now ? std::max(1, Clamp(next - now)) : 1;
    }
};
}

#endif
