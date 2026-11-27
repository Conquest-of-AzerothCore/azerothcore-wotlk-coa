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

    enum class ArmorTier : std::uint8_t
    {
        Cloth = 0,
        Leather = 1,
        Mail = 2,
        Plate = 3
    };

    struct GearValues
    {
        float health = 0.0f;
        float armor = 0.0f;
        float shieldArmor = 0.0f;
        bool hasShield = false;
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
        float armor = 0.0f;

        bool Empty() const
        {
            return health == 0.0f && armor == 0.0f;
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

    inline float Gain(float own, float target)
    {
        return target > own ? target - own : 0.0f;
    }

    inline float PlayerStaminaHealth(std::uint32_t stamina)
    {
        std::uint32_t const base = std::min<std::uint32_t>(stamina, 20);
        std::uint32_t const extra = stamina > 20 ? stamina - 20 : 0;
        return static_cast<float>(base + 10 * extra);
    }

    inline float PlayerOutputHealth(LevelValues const& values)
    {
        return static_cast<float>(values.health) + PlayerStaminaHealth(values.stats[2]);
    }

    inline constexpr std::array<std::uint32_t, 12> GearAnchorLevels = {
        10, 15, 20, 25, 29, 35, 40, 45, 46, 49, 55, 59
    };

    inline float InterpolateLevelTable(std::uint32_t level, std::array<float, 12> const& values)
    {
        if (level <= GearAnchorLevels.front())
            return values.front();
        if (level >= GearAnchorLevels.back())
            return values.back();

        for (std::size_t index = 1; index < GearAnchorLevels.size(); ++index)
        {
            if (level <= GearAnchorLevels[index])
            {
                std::uint32_t const lowLevel = GearAnchorLevels[index - 1];
                std::uint32_t const highLevel = GearAnchorLevels[index];
                float const fraction = static_cast<float>(level - lowLevel) /
                    static_cast<float>(highLevel - lowLevel);
                return values[index - 1] + (values[index] - values[index - 1]) * fraction;
            }
        }
        return values.back();
    }

    inline float GearHealthBudget(std::uint32_t level)
    {
        static constexpr std::array<float, 12> Values = {
            140.0f, 185.0f, 240.0f, 305.0f, 365.0f, 460.0f, 545.0f, 650.0f, 665.0f, 705.0f, 820.0f, 900.0f
        };
        return InterpolateLevelTable(level, Values);
    }

    inline float GearArmorBudget(ArmorTier tier, std::uint32_t level, bool rebornArmor)
    {
        static constexpr std::array<std::array<float, 12>, 4> RebornValues = {{
            {  98.0f, 130.0f, 162.0f, 195.0f,  221.0f,  260.0f,  291.0f,  321.0f,  327.0f,  344.0f,  376.0f,  394.0f },
            { 192.0f, 250.0f, 310.0f, 375.0f,  422.0f,  496.0f,  556.0f,  613.0f,  624.0f,  659.0f,  718.0f,  757.0f },
            { 386.0f, 505.0f, 625.0f, 751.0f,  852.0f,  999.0f, 1121.0f, 1235.0f, 1267.0f, 1362.0f, 1490.0f, 1569.0f },
            { 496.0f, 638.0f, 780.0f, 929.0f, 1046.0f, 1220.0f, 1367.0f, 1512.0f, 2258.0f, 2397.0f, 2649.0f, 2798.0f }
        }};
        static constexpr std::array<std::array<float, 12>, 4> StockValues = {{
            { 460.0f, 518.0f, 583.0f, 657.0f, 722.0f, 832.0f, 938.0f, 1055.0f, 1081.0f, 1160.0f, 1338.0f, 1471.0f },
            { 615.0f, 693.0f, 780.0f, 878.0f, 966.0f, 1114.0f, 1254.0f, 1412.0f, 1447.0f, 1552.0f, 1789.0f, 1967.0f },
            { 706.0f, 794.0f, 894.0f, 1007.0f, 1107.0f, 1277.0f, 1437.0f, 1618.0f, 1658.0f, 1779.0f, 2051.0f, 2255.0f },
            { 793.0f, 893.0f, 1006.0f, 1132.0f, 1245.0f, 1435.0f, 1616.0f, 1819.0f, 1864.0f, 2000.0f, 2306.0f, 2536.0f }
        }};
        std::size_t const index = std::min<std::size_t>(static_cast<std::size_t>(tier), 3);
        return InterpolateLevelTable(level, (rebornArmor ? RebornValues : StockValues)[index]);
    }

    inline float GearShieldArmorBudget(std::uint32_t level, bool rebornArmor)
    {
        static constexpr std::array<float, 12> RebornValues = {
            130.0f, 231.0f, 364.0f, 520.0f, 644.0f, 833.0f, 985.0f, 1132.0f, 1160.0f, 1244.0f, 1408.0f, 1513.0f
        };
        static constexpr std::array<float, 12> StockValues = {
            326.0f, 367.0f, 414.0f, 466.0f, 512.0f, 590.0f, 665.0f,  748.0f,  767.0f,  823.0f,  948.0f, 1043.0f
        };
        return InterpolateLevelTable(level, rebornArmor ? RebornValues : StockValues);
    }

    inline float GearCatchUpAmount(float ownBudget, float targetBudget, float currentGear, float scale)
    {
        if (scale <= 0.0f)
            return 0.0f;
        float const scaledOwn = ownBudget * scale;
        float const scaledTarget = targetBudget * scale;
        float const floorGap = Gain(std::max(currentGear, 0.0f), scaledTarget);
        float const levelGap = Gain(scaledOwn, scaledTarget);
        return std::round(std::min(levelGap, floorGap));
    }

    inline Lift PlayerGearLift(std::uint32_t ownLevel, std::uint32_t targetLevel, ArmorTier ownTier,
        ArmorTier targetTier, bool rebornArmor, GearValues const& gear, float scale = 1.0f)
    {
        Lift lift;
        if (targetLevel <= ownLevel || scale <= 0.0f)
            return lift;

        lift.health = GearCatchUpAmount(GearHealthBudget(ownLevel), GearHealthBudget(targetLevel),
            gear.health, scale);
        lift.armor = GearCatchUpAmount(GearArmorBudget(ownTier, ownLevel, rebornArmor),
            GearArmorBudget(targetTier, targetLevel, rebornArmor), gear.armor, scale);
        if (gear.hasShield)
            lift.armor += GearCatchUpAmount(GearShieldArmorBudget(ownLevel, rebornArmor),
                GearShieldArmorBudget(targetLevel, rebornArmor), gear.shieldArmor, scale);
        return lift;
    }

    inline Lift LiftBetween(LevelValues const& own, LevelValues const& target)
    {
        Lift lift;
        lift.health = Gain(own.health, target.health);
        return lift;
    }

    inline Lift PlayerLiftBetween(LevelValues const& own, LevelValues const& target)
    {
        Lift lift;
        lift.health = Gain(PlayerOutputHealth(own), PlayerOutputHealth(target));
        return lift;
    }

    inline std::uint32_t CappedLiftLevel(std::uint32_t level, std::uint32_t top, std::uint32_t maxLiftLevels)
    {
        std::uint32_t const capped = maxLiftLevels == 0 ? top : std::min(top, level + maxLiftLevels);
        return std::max(capped, level);
    }

    inline float OutputRatio(float ownHealth, float liftedHealth)
    {
        return ownHealth > 0.0f && liftedHealth > ownHealth ? liftedHealth / ownHealth : 1.0f;
    }

    inline float ClampOutputScale(float scale)
    {
        return std::isfinite(scale) && scale >= 0.0f ? scale : 1.0f;
    }

    inline std::int32_t LevelScaledPointsDelta(std::uint32_t ownLevel, std::uint32_t liftedLevel,
        std::uint32_t baseLevel, std::uint32_t spellLevel, std::uint32_t maxLevel, float pointsPerLevel)
    {
        if (liftedLevel <= ownLevel || pointsPerLevel == 0.0f)
            return 0;

        auto const effectiveLevel = [baseLevel, spellLevel, maxLevel](std::uint32_t level) -> std::int32_t
        {
            std::int32_t effective = static_cast<std::int32_t>(level);
            if (maxLevel > 0 && effective > static_cast<std::int32_t>(maxLevel))
                effective = static_cast<std::int32_t>(maxLevel);
            else if (effective < static_cast<std::int32_t>(baseLevel))
                effective = static_cast<std::int32_t>(baseLevel);
            effective -= static_cast<std::int32_t>(std::max(baseLevel, spellLevel));
            return effective;
        };

        std::int32_t const ownPoints = static_cast<std::int32_t>(
            static_cast<float>(effectiveLevel(ownLevel)) * pointsPerLevel);
        std::int32_t const liftedPoints = static_cast<std::int32_t>(
            static_cast<float>(effectiveLevel(liftedLevel)) * pointsPerLevel);
        return liftedPoints - ownPoints;
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
