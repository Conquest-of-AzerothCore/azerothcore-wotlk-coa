/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLEGROUND_BRACKETS_POLICY_H
#define ASCENSION_BATTLEGROUND_BRACKETS_POLICY_H

#include <algorithm>
#include <array>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <limits>
#include <optional>
#include <string_view>
#include <vector>

namespace AscensionBattlegroundBracketsPolicy
{
    inline constexpr std::uint32_t HighestWidenableLevel = 59;

    struct LevelRange
    {
        std::uint32_t minLevel;
        std::uint32_t maxLevel;
    };

    struct BracketRow
    {
        std::uint32_t bracketId;
        std::uint32_t minLevel;
        std::uint32_t maxLevel;
    };

    struct LevelValues
    {
        std::uint32_t health;
        std::uint32_t mana;
        std::array<std::uint32_t, 5> stats;
    };

    struct Lift
    {
        float health = 0.0f;
        float stamina = 0.0f;

        bool Empty() const
        {
            return health == 0.0f && stamina == 0.0f;
        }
    };

    inline std::string_view Trim(std::string_view text)
    {
        while (!text.empty() && (text.front() == ' ' || text.front() == '\t'))
            text.remove_prefix(1);
        while (!text.empty() && (text.back() == ' ' || text.back() == '\t'))
            text.remove_suffix(1);
        return text;
    }

    inline std::optional<std::uint32_t> ParseLevel(std::string_view text)
    {
        text = Trim(text);
        if (text.empty())
            return std::nullopt;
        std::uint32_t value = 0;
        auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), value);
        if (error != std::errc() || end != text.data() + text.size())
            return std::nullopt;
        return value;
    }

    inline std::optional<LevelRange> ParseRange(std::string_view token)
    {
        std::size_t const dash = token.find('-');
        if (dash == std::string_view::npos || token.find('-', dash + 1) != std::string_view::npos)
            return std::nullopt;
        auto minLevel = ParseLevel(token.substr(0, dash));
        auto maxLevel = ParseLevel(token.substr(dash + 1));
        if (!minLevel || !maxLevel || *minLevel < 1 || *minLevel > *maxLevel || *maxLevel > HighestWidenableLevel)
            return std::nullopt;
        return LevelRange{ *minLevel, *maxLevel };
    }

    inline std::optional<std::vector<LevelRange>> ParseRanges(std::string_view text)
    {
        std::vector<LevelRange> ranges;
        while (true)
        {
            std::size_t const comma = text.find(',');
            auto range = ParseRange(text.substr(0, comma));
            if (!range || (!ranges.empty() && ranges.back().maxLevel >= range->minLevel))
                return std::nullopt;
            ranges.push_back(*range);
            if (comma == std::string_view::npos)
                return ranges;
            text.remove_prefix(comma + 1);
        }
    }

    inline std::optional<std::vector<BracketRow>> Widen(std::vector<BracketRow> const& stockBelowSixty,
        std::vector<LevelRange> const& ranges)
    {
        std::vector<BracketRow> widened;
        for (LevelRange const& range : ranges)
        {
            std::optional<BracketRow> merged;
            for (BracketRow const& row : stockBelowSixty)
            {
                bool const overlaps = row.minLevel <= range.maxLevel && row.maxLevel >= range.minLevel;
                if (!overlaps)
                    continue;
                if (row.minLevel < range.minLevel || row.maxLevel > range.maxLevel)
                    return std::nullopt;
                if (!merged)
                {
                    merged = row;
                    continue;
                }
                merged->bracketId = std::min(merged->bracketId, row.bracketId);
                merged->minLevel = std::min(merged->minLevel, row.minLevel);
                merged->maxLevel = std::max(merged->maxLevel, row.maxLevel);
            }
            if (merged)
                widened.push_back(*merged);
        }
        return widened;
    }

    inline std::size_t RangeIndexOf(std::vector<LevelRange> const& ranges, BracketRow const& row)
    {
        for (std::size_t index = 0; index < ranges.size(); ++index)
            if (ranges[index].minLevel <= row.minLevel && row.maxLevel <= ranges[index].maxLevel)
                return index;
        return ranges.size();
    }

    inline std::optional<std::size_t> FirstMapWithMisalignedId(
        std::vector<std::vector<BracketRow>> const& widenedPerMap, std::vector<LevelRange> const& ranges)
    {
        std::vector<std::optional<std::uint32_t>> leadIds(ranges.size() + 1);
        for (std::size_t map = 0; map < widenedPerMap.size(); ++map)
        {
            for (BracketRow const& row : widenedPerMap[map])
            {
                std::optional<std::uint32_t>& leadId = leadIds[RangeIndexOf(ranges, row)];
                if (leadId && *leadId != row.bracketId)
                    return map;
                leadId = row.bracketId;
            }
        }
        return std::nullopt;
    }

    inline float Gain(std::uint32_t own, std::uint32_t target)
    {
        return target > own ? static_cast<float>(target - own) : 0.0f;
    }

    inline Lift LiftBetween(LevelValues const& own, LevelValues const& target)
    {
        Lift lift;
        lift.health = Gain(own.health, target.health);
        lift.stamina = Gain(own.stats[2], target.stats[2]);
        return lift;
    }

    inline std::uint32_t CappedLiftLevel(std::uint32_t level, std::uint32_t top, std::uint32_t maxLiftLevels)
    {
        std::uint32_t const capped = maxLiftLevels == 0 ? top : std::min(top, level + maxLiftLevels);
        return std::max(capped, level);
    }

    inline float PlayerStaminaHealth(std::uint32_t stamina)
    {
        std::uint32_t const base = std::min<std::uint32_t>(stamina, 20);
        std::uint32_t const extra = stamina > 20 ? stamina - 20 : 0;
        return static_cast<float>(base + 10 * extra);
    }

    inline float OutputRatio(float ownHealth, float liftedHealth)
    {
        return ownHealth > 0.0f && liftedHealth > ownHealth ? liftedHealth / ownHealth : 1.0f;
    }

    template <typename Integer>
    inline Integer SaturatedScale(Integer amount, float ratio)
    {
        double const scaled = std::round(static_cast<double>(amount) * static_cast<double>(ratio));
        if (scaled >= static_cast<double>(std::numeric_limits<Integer>::max()))
            return std::numeric_limits<Integer>::max();
        if (scaled <= static_cast<double>(std::numeric_limits<Integer>::min()))
            return std::numeric_limits<Integer>::min();
        return static_cast<Integer>(scaled);
    }

    inline std::uint32_t ScaleAmount(std::uint32_t amount, float ratio)
    {
        return SaturatedScale(amount, ratio);
    }

    inline std::int32_t ScaleAmount(std::int32_t amount, float ratio)
    {
        return SaturatedScale(amount, ratio);
    }

    inline std::uint32_t KeptHealth(std::uint32_t health, std::uint32_t oldMax, std::uint32_t newMax)
    {
        if (oldMax == 0 || health == 0)
            return health;
        double const scaled = static_cast<double>(health) * static_cast<double>(newMax) / static_cast<double>(oldMax);
        std::uint32_t const kept = static_cast<std::uint32_t>(std::lround(scaled));
        return std::min(std::max(kept, 1u), newMax);
    }
}

#endif
