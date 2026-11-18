/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLEGROUND_BRACKETS_POLICY_H
#define ASCENSION_BATTLEGROUND_BRACKETS_POLICY_H

#include <algorithm>
#include <array>
#include <charconv>
#include <cstdint>
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
        float mana = 0.0f;
        std::array<float, 5> stats{};

        bool Empty() const
        {
            return health == 0.0f && mana == 0.0f
                && std::all_of(stats.begin(), stats.end(), [](float stat) { return stat == 0.0f; });
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

    inline float Gain(std::uint32_t own, std::uint32_t target)
    {
        return target > own ? static_cast<float>(target - own) : 0.0f;
    }

    inline Lift LiftBetween(LevelValues const& own, LevelValues const& target)
    {
        Lift lift;
        lift.health = Gain(own.health, target.health);
        lift.mana = Gain(own.mana, target.mana);
        for (std::size_t i = 0; i < lift.stats.size(); ++i)
            lift.stats[i] = Gain(own.stats[i], target.stats[i]);
        return lift;
    }
}

#endif
