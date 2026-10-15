#ifndef ASCENSION_CHANGELOG_DATA_H
#define ASCENSION_CHANGELOG_DATA_H

#include <array>
#include <cstdint>

namespace AscensionChangelog
{
enum class Field : std::uint8_t
{
    BasePoints,
    RecoveryTime,
    CategoryRecoveryTime,
    Duration,
    InitialPeriodicTick,
    ForceMoveForward
};

struct Change
{
    std::uint32_t SpellId;
    std::uint32_t SourceId;
    std::uint32_t Family;
    Field Property;
    std::uint8_t EffectIndex;
    std::uint32_t EffectType;
    std::uint32_t AuraType;
    std::int32_t Before;
    std::int32_t After;
    std::uint32_t DurationEntry;
};

inline constexpr std::array<Change, 61> Changes =
{{
    {500950, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {500950, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501114, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501114, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501115, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501115, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501116, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501116, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501117, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501117, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501118, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501118, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {501344, 71850, 21, Field::BasePoints, 0, 6, 3, 15, 26, 0},
    {501344, 71850, 21, Field::BasePoints, 2, 2, 0, 9, 15, 0},
    {501345, 71851, 21, Field::BasePoints, 0, 6, 3, 22, 37, 0},
    {501345, 71851, 21, Field::BasePoints, 2, 2, 0, 15, 26, 0},
    {501346, 71852, 21, Field::BasePoints, 0, 6, 3, 29, 49, 0},
    {501346, 71852, 21, Field::BasePoints, 2, 2, 0, 18, 31, 0},
    {501347, 71853, 21, Field::BasePoints, 0, 6, 3, 36, 61, 0},
    {501347, 71853, 21, Field::BasePoints, 2, 2, 0, 23, 39, 0},
    {501348, 71854, 21, Field::BasePoints, 0, 6, 3, 43, 73, 0},
    {501348, 71854, 21, Field::BasePoints, 2, 2, 0, 28, 48, 0},
    {501349, 71855, 21, Field::BasePoints, 0, 6, 3, 51, 87, 0},
    {501349, 71855, 21, Field::BasePoints, 2, 2, 0, 35, 60, 0},
    {520270, 71835, 21, Field::BasePoints, 0, 6, 227, 49, 69, 0},
    {520708, 71836, 21, Field::BasePoints, 0, 6, 227, 79, 111, 0},
    {520709, 71837, 21, Field::BasePoints, 0, 6, 227, 94, 132, 0},
    {520753, 71880, 27, Field::Duration, 1, 6, 228, 5000, 15000, 8},
    {562024, 71838, 21, Field::BasePoints, 0, 6, 227, 112, 157, 0},
    {562025, 71839, 21, Field::BasePoints, 0, 6, 227, 144, 202, 0},
    {572577, 71871, 19, Field::CategoryRecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {572577, 71871, 19, Field::RecoveryTime, 0, 6, 8, 18000, 14000, 0},
    {681095, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {681212, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {681213, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {681214, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {681215, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {681216, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {681217, 71833, 21, Field::InitialPeriodicTick, 0, 6, 227, 0, 1, 0},
    {705467, 71848, 21, Field::BasePoints, 0, 6, 108, 9, 14, 0},
    {705500, 71858, 21, Field::BasePoints, 1, 6, 107, 9, 24, 0},
    {707889, 71848, 21, Field::BasePoints, 0, 6, 108, 19, 29, 0},
    {800162, 71849, 21, Field::BasePoints, 0, 6, 3, 8, 14, 0},
    {800162, 71849, 21, Field::BasePoints, 2, 2, 0, 4, 7, 0},
    {802138, 71832, 21, Field::RecoveryTime, 0, 35, 81, 180000, 120000, 0},
    {804051, 71826, 21, Field::Duration, 0, 28, 0, 15000, 30000, 9},
    {805751, 71877, 21, Field::ForceMoveForward, 0, 6, 241, 1, 0, 0},
    {805754, 71860, 21, Field::BasePoints, 0, 2, 0, 39, 59, 0},
    {805754, 71860, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
    {807279, 71861, 21, Field::BasePoints, 0, 2, 0, 80, 120, 0},
    {807279, 71861, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
    {807280, 71862, 21, Field::BasePoints, 0, 2, 0, 137, 206, 0},
    {807280, 71862, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
    {807281, 71863, 21, Field::BasePoints, 0, 2, 0, 182, 273, 0},
    {807281, 71863, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
    {807282, 71864, 21, Field::BasePoints, 0, 2, 0, 246, 369, 0},
    {807282, 71864, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
    {807283, 71865, 21, Field::BasePoints, 0, 2, 0, 333, 500, 0},
    {807283, 71865, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
    {807284, 71866, 21, Field::BasePoints, 0, 2, 0, 488, 732, 0},
    {807284, 71866, 21, Field::BasePoints, 1, 31, 0, 199, 299, 0},
}};
}

#endif
