#ifndef COA_ASCENSION_ITEM_SCALING_POLICY_H
#define COA_ASCENSION_ITEM_SCALING_POLICY_H

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <map>
#include <string_view>
#include <utility>
#include <vector>

namespace ItemScaling
{
constexpr std::uint32_t FirstScaledEntry = 4400001;
constexpr std::uint32_t LastScaledEntry = 4912583;
constexpr std::uint32_t ItemClassWeapon = 2;
constexpr std::uint32_t ItemClassArmor = 4;
constexpr std::uint32_t MinimumQuality = 0;
constexpr std::uint32_t MaximumQuality = 5;
constexpr std::uint32_t InventoryTypeShirt = 4;
constexpr std::uint32_t InventoryTypeTabard = 19;
constexpr std::uint32_t RequiredLevelGap = 5;
constexpr std::uint32_t LiftStep = 5;
constexpr std::uint32_t MaximumCurveLevel = 300;
constexpr std::string_view WorldforgedMarker = "@Worldforged@";

inline bool IsScaledEntry(std::uint32_t entry)
{
    return entry >= FirstScaledEntry && entry <= LastScaledEntry;
}

inline bool EligibleItem(std::uint32_t quality, std::uint32_t itemClass, std::uint32_t inventoryType,
    std::uint32_t itemLevel, std::uint32_t scalingStatDistribution, std::uint32_t startQuest)
{
    return quality >= MinimumQuality && quality <= MaximumQuality
        && (itemClass == ItemClassWeapon || itemClass == ItemClassArmor)
        && inventoryType != 0 && inventoryType != InventoryTypeShirt && inventoryType != InventoryTypeTabard
        && itemLevel != 0 && scalingStatDistribution == 0 && startQuest == 0;
}

inline bool IsWorldforgedDescription(std::string_view description)
{
    return description.compare(0, WorldforgedMarker.size(), WorldforgedMarker) == 0;
}

inline std::uint32_t QuestLift(std::int32_t questLevel, std::uint32_t scaledQuestLevel)
{
    if (questLevel <= 0 || scaledQuestLevel <= std::uint32_t(questLevel))
        return 0;
    return scaledQuestLevel - std::uint32_t(questLevel);
}

inline std::uint32_t LootLift(std::uint32_t creatureLevel, std::uint32_t viewLevel)
{
    return viewLevel > creatureLevel ? viewLevel - creatureLevel : 0;
}

inline std::uint32_t ContentLift(std::uint32_t itemLevel, std::uint32_t playerLevel, std::uint32_t offset)
{
    return LootLift(itemLevel, playerLevel > offset ? playerLevel - offset : 1);
}

inline std::uint32_t SteppedLift(std::uint32_t lift)
{
    return lift / LiftStep * LiftStep;
}

inline std::uint32_t LiftedRequiredLevel(std::uint32_t requiredLevel, std::uint32_t itemLevel, std::uint32_t lift,
    std::uint32_t maxPlayerLevel)
{
    if (!lift)
        return requiredLevel;
    if (!requiredLevel)
    {
        std::uint32_t const liftedItemLevel = itemLevel + lift;
        return liftedItemLevel > RequiredLevelGap ? std::min(liftedItemLevel - RequiredLevelGap, maxPlayerLevel) : 0;
    }
    return std::max(requiredLevel, std::min(requiredLevel + lift, maxPlayerLevel));
}

inline std::int32_t ScaleSigned(std::int32_t value, double ratio)
{
    if (ratio <= 1.0)
        return value;
    return std::int32_t(std::lround(double(value) * ratio));
}

inline std::uint32_t ScaleUnsigned(std::uint32_t value, double ratio)
{
    if (ratio <= 1.0)
        return value;
    return std::uint32_t(std::min(std::round(double(value) * ratio), double(UINT32_MAX)));
}

inline float ScaleFloat(float value, double ratio)
{
    if (ratio <= 1.0)
        return value;
    return float(std::round(double(value) * ratio));
}

inline double PointsRatio(std::uint32_t fromPoints, std::uint32_t toPoints)
{
    return fromPoints && toPoints > fromPoints ? double(toPoints) / double(fromPoints) : 1.0;
}

class LevelCurve
{
public:
    void Add(std::uint32_t level, double value)
    {
        if (level && level <= MaximumCurveLevel && value > 0.0)
            _samples[level].push_back(value);
    }

    void Finish()
    {
        _values.assign(MaximumCurveLevel + 1, 0.0);
        if (_samples.size() < 3)
            return;

        std::map<std::uint32_t, double> medians;
        for (auto& [level, values] : _samples)
        {
            std::sort(values.begin(), values.end());
            std::size_t const middle = values.size() / 2;
            medians[level] = values.size() % 2 ? values[middle] : (values[middle - 1] + values[middle]) / 2.0;
        }

        double highest = 0.0;
        auto upper = medians.begin();
        for (std::uint32_t level = medians.begin()->first; level <= medians.rbegin()->first; ++level)
        {
            while (upper->first < level)
                ++upper;
            double value = upper->second;
            if (upper->first != level)
            {
                auto const lower = std::prev(upper);
                double const share = double(level - lower->first) / double(upper->first - lower->first);
                value = lower->second + (upper->second - lower->second) * share;
            }
            highest = std::max(highest, value);
            _values[level] = highest;
        }
    }

    double At(std::uint32_t level) const
    {
        return level < _values.size() ? _values[level] : 0.0;
    }

private:
    std::map<std::uint32_t, std::vector<double>> _samples;
    std::vector<double> _values;
};

inline double CurveRatio(LevelCurve const& curve, std::uint32_t fromLevel, std::uint32_t toLevel, double fallback)
{
    double const from = curve.At(fromLevel);
    double const to = curve.At(toLevel);
    return from > 0.0 && to > 0.0 ? to / from : fallback;
}

inline bool Disenchantable(std::uint32_t disenchantId, std::uint32_t requiredSkill)
{
    return disenchantId && std::int32_t(requiredSkill) >= 0;
}

struct DisenchantBracket
{
    std::uint32_t itemLevel = 0;
    std::uint32_t disenchantId = 0;
    std::uint32_t requiredSkill = 0;
};

class DisenchantLadder
{
public:
    void Add(std::uint32_t itemLevel, std::uint32_t disenchantId, std::uint32_t requiredSkill)
    {
        if (itemLevel && Disenchantable(disenchantId, requiredSkill))
            ++_donors[itemLevel][{ disenchantId, requiredSkill }];
    }

    DisenchantBracket AtOrBelow(std::uint32_t itemLevel) const
    {
        auto const above = _donors.upper_bound(itemLevel);
        if (above == _donors.begin())
            return {};

        auto const& [donorLevel, brackets] = *std::prev(above);
        auto const common = std::max_element(brackets.begin(), brackets.end(),
            [](auto const& left, auto const& right) { return left.second < right.second; });
        return { donorLevel, common->first.first, common->first.second };
    }

private:
    std::map<std::uint32_t, std::map<std::pair<std::uint32_t, std::uint32_t>, std::uint32_t>> _donors;
};

inline DisenchantBracket NearestDisenchantBracket(DisenchantBracket const& sameSubClass,
    DisenchantBracket const& sameSlot)
{
    return sameSlot.itemLevel > sameSubClass.itemLevel ? sameSlot : sameSubClass;
}
}

#endif
