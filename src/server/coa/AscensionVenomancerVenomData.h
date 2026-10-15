/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_VENOMANCER_VENOM_DATA_H
#define ASCENSION_VENOMANCER_VENOM_DATA_H

#include "Define.h"
#include <array>

namespace AscensionVenomancerVenomData
{
struct Activation
{
    uint32 Id;
    uint32 Helper;
    uint32 FamilyMask1;
    uint8 Chance;
    uint8 Stacks;
};

constexpr std::array<Activation, 6> ACTIVATIONS =
{{
    {630868, 630869, 1024, 20, 1},
    {805731, 805895, 64, 30, 1},
    {805775, 805894, 2, 25, 1},
    {805776, 805896, 0, 30, 1},
    {805777, 805897, 4194304, 30, 2},
    {805778, 706000, 0, 35, 2},
}};

struct Rank
{
    uint32 Id;
    int32 BasePoints;
    int32 DieSides;
    float PointsPerLevel;
};

constexpr std::array<Rank, 8> MYCOSIS =
{{
    {572150, 201, 31, 4.2249999f},
    {572151, 304, 49, 7.5562501f},
    {572153, 392, 70, 8.20147991f},
    {572154, 493, 92, 8.82491016f},
    {572155, 602, 112, 7.7750001f},
    {572156, 744, 128, 6.19999981f},
    {573355, 877, 138, 5.9749999f},
    {804986, 152, 17, 2.42000008f},
}};

constexpr std::array<Rank, 7> SPORE =
{{
    {503983, 43, 4, 0.850665987f},
    {503984, 76, 6, 0.75f},
    {503985, 99, 7, 0.758333027f},
    {503986, 127, 8, 1.375f},
    {572868, 157, 8, 1.29999995f},
    {572869, 190, 8, 1.41250002f},
    {804983, 29, 3, 0.400000006f},
}};
}

#endif
