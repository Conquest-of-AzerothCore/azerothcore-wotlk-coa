/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_QUEST_SCALING_H
#define COA_ASCENSION_QUEST_SCALING_H

#include "LocalLevelScaling.h"
#include <array>
#include <cstdint>

namespace QuestScalingTable
{
constexpr std::uint32_t RecordFields = 15;
constexpr std::uint32_t RecordSize = RecordFields * sizeof(std::int32_t);
constexpr std::uint32_t QuestField = 0;
constexpr std::uint32_t MinLevelField = 1;
constexpr std::uint32_t MaxLevelField = 2;
constexpr std::uint32_t FirstLevelField = 3;
constexpr std::uint32_t FirstOffsetField = 9;

inline LocalLevelScaling::QuestCurve CurveFromRecord(std::array<std::int32_t, RecordFields> const& record)
{
    LocalLevelScaling::QuestCurve curve;
    curve.MinLevel = record[MinLevelField];
    curve.MaxLevel = record[MaxLevelField];
    for (std::uint32_t i = 0; i < curve.Points.size(); ++i)
        if (std::int32_t const level = record[FirstLevelField + i])
            curve.Points[curve.Count++] = { level, record[FirstOffsetField + i] };
    return curve;
}
}

#endif
