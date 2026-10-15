/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef CLASSIC_PLUS_STATS_H
#define CLASSIC_PLUS_STATS_H

#include "Define.h"
#include "SharedDefines.h"
#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>

namespace ClassicPlusStats
{
constexpr uint8 VanillaMaxLevel = 60;
constexpr uint8 WotlkMaxLevel = 80;

struct StatCurve
{
    float Base;
    float PerPoint;
};

constexpr bool UsesVanillaFormulas(uint32 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR:
        case CLASS_PALADIN:
        case CLASS_HUNTER:
        case CLASS_ROGUE:
        case CLASS_PRIEST:
        case CLASS_SHAMAN:
        case CLASS_MAGE:
        case CLASS_WARLOCK:
        case CLASS_DRUID:
            return true;
        default:
            return false;
    }
}

constexpr float VanillaWeight(uint8 level)
{
    if (level <= VanillaMaxLevel)
        return 1.0f;
    if (level >= WotlkMaxLevel)
        return 0.0f;
    return float(WotlkMaxLevel - level) / float(WotlkMaxLevel - VanillaMaxLevel);
}

constexpr float Blend(float vanilla, float current, uint8 level)
{
    float const weight = VanillaWeight(level);
    return vanilla * weight + current * (1.0f - weight);
}

// The CoA client's gtChanceToMeleeCrit row for a level 10 Warrior is 0.009811 where stock 3.3.5 has 0.002012;
// *_dbc overrides may not replace client rows, so correct it here.
constexpr float CorrectedClientMeleeCritRatio(uint32 playerClass, uint8 level, float clientRatio)
{
    return playerClass == CLASS_WARRIOR && level == 10 ? 0.002012f : clientRatio;
}

using LevelRates = std::array<float, VanillaMaxLevel>;

struct AgilityRates
{
    uint32 Class;
    LevelRates AgilityPerCrit;
    LevelRates AgilityPerDodge;
};

// Agility per 1% crit and dodge sniffed from 1.12, as loaded by vmangos (player_crit_per_agility and
// player_dodge_per_agility, sql/migrations 20260703210621, 20260711022757 and 20260711025640). vmangos
// interpolates linearly over the levels without a capture, stored here as 0.
constexpr std::array<AgilityRates, 9> SniffedAgilityRates =
{{
    {
        CLASS_WARRIOR,
        {{ 4.0f, 4.19992f, 4.19992f, 4.39947f, 4.59982f, 4.80077f, 4.80077f, 5.0f, 5.20021f, 5.20021f,
           5.39957f, 5.5991f, 5.9988f, 6.19963f, 6.39795f, 6.60066f, 6.7981f, 7.19942f, 7.40192f, 7.80031f,
           7.80031f, 8.0f, 8.40336f, 8.59845f, 9.0009f, 9.19963f, 9.3985f, 9.80392f, 10.0f, 10.395f,
           10.6045f, 10.7991f, 11.1982f, 11.4025f, 11.8064f, 12.0048f, 12.1951f, 12.5945f, 12.8041f, 13.1926f,
           13.6054f, 13.7931f, 14.2045f, 14.4092f, 14.7929f, 14.9925f, 15.4083f, 15.7978f, 16.0f, 16.3934f,
           16.8067f, 17.0068f, 17.3913f, 17.7936f, 18.2149f, 18.4162f, 18.797f, 19.1939f, 0.0f, 20.0f }},
        {{ 4.0f, 4.19992f, 4.19992f, 4.39947f, 4.59982f, 4.80077f, 4.80077f, 5.0f, 5.20021f, 5.20021f,
           5.39957f, 5.5991f, 5.9988f, 6.19963f, 6.39795f, 6.60066f, 6.7981f, 7.19942f, 7.40193f, 7.80031f,
           7.80031f, 8.0f, 8.40336f, 8.59845f, 9.0009f, 9.19963f, 9.3985f, 9.80392f, 10.0f, 10.395f,
           10.6045f, 10.7991f, 11.1982f, 11.4025f, 11.8064f, 12.0048f, 12.1951f, 12.5945f, 12.8041f, 13.1926f,
           13.6054f, 13.7931f, 14.2045f, 14.4092f, 14.7929f, 14.9925f, 15.4083f, 15.7978f, 16.0f, 16.3934f,
           16.8067f, 17.0068f, 17.3913f, 17.7936f, 18.2149f, 18.4162f, 18.797f, 19.1939f, 0.0f, 20.0f }}
    },
    {
        CLASS_PALADIN,
        {{ 4.65116f, 4.88281f, 4.88281f, 5.11509f, 5.11509f, 5.34759f, 5.34759f, 5.58036f, 5.58036f, 5.81395f,
           5.81395f, 6.04595f, 6.51042f, 6.51042f, 6.97837f, 6.97837f, 7.20981f, 7.6746f, 7.6746f, 8.1367f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 16.0514f, 16.5016f,
           16.7504f, 16.9779f, 17.452f, 17.6678f, 18.1488f, 18.3824f, 18.5874f, 19.084f, 19.305f, 19.7628f }},
        {{ 4.65116f, 4.88281f, 4.88281f, 5.11509f, 5.11509f, 5.34759f, 5.34759f, 5.58036f, 5.58036f, 5.81395f,
           5.81395f, 6.04595f, 6.51042f, 6.51042f, 6.97837f, 6.97837f, 7.20981f, 7.6746f, 7.6746f, 8.1367f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 16.0514f, 16.5016f,
           16.7504f, 16.9779f, 17.452f, 17.6678f, 18.1488f, 18.3824f, 18.5874f, 19.084f, 19.305f, 19.7628f }}
    },
    {
        CLASS_HUNTER,
        {{ 4.59982f, 4.80077f, 5.0f, 5.39957f, 5.5991f, 5.80046f, 5.9988f, 6.19963f, 6.60066f, 6.7981f,
           7.40193f, 8.40336f, 9.19963f, 10.0f, 11.0011f, 11.6009f, 12.4069f, 13.4048f, 14.2045f, 15.1976f,
           15.7978f, 16.8067f, 17.6056f, 18.5874f, 19.4175f, 20.202f, 21.1864f, 21.978f, 22.9885f, 23.9808f,
           24.57f, 25.5754f, 26.5957f, 27.3973f, 28.4091f, 29.2398f, 30.2115f, 31.1526f, 32.1543f, 33.0033f,
           33.7838f, 34.8432f, 35.8423f, 36.7647f, 37.7358f, 0.0f, 39.5257f, 40.8163f, 41.841f, 42.735f,
           43.6681f, 44.6429f, 45.6621f, 46.729f, 0.0f, 48.5437f, 49.7512f, 50.7614f, 52.0833f, 52.9101f }},
        {{ 2.29991f, 2.39981f, 2.5f, 2.69978f, 2.80034f, 2.90023f, 3.0003f, 3.09981f, 3.30033f, 3.4002f,
           3.69959f, 4.19992f, 4.59982f, 5.0f, 5.50055f, 5.80046f, 6.19963f, 6.69792f, 7.10227f, 7.59878f,
           7.89889f, 8.40336f, 8.80282f, 9.30233f, 9.69932f, 10.101f, 10.6045f, 11.0011f, 11.4943f, 12.0048f,
           12.3001f, 12.8041f, 13.2979f, 13.6986f, 14.2045f, 14.5985f, 15.1057f, 15.6006f, 16.1031f, 16.5016f,
           16.8919f, 17.3913f, 17.8891f, 18.4162f, 18.9036f, 0.0f, 19.802f, 20.4082f, 20.9205f, 21.4133f,
           0.0f, 22.3214f, 22.779f, 23.4192f, 0.0f, 24.2718f, 24.8756f, 25.3807f, 25.974f, 26.5252f }}
    },
    {
        CLASS_ROGUE,
        {{ 2.29991f, 2.39981f, 2.5f, 2.69978f, 2.80034f, 2.90023f, 3.09981f, 3.2f, 3.30033f, 3.50017f,
           3.90016f, 4.29923f, 4.80077f, 0.0f, 0.0f, 6.19963f, 6.60066f, 7.10227f, 7.59878f, 8.09717f,
           8.59845f, 9.0009f, 9.49668f, 9.90099f, 10.5042f, 11.0011f, 11.4025f, 11.9048f, 12.4069f, 13.0039f,
           13.4048f, 13.9082f, 14.4092f, 14.9031f, 15.2765f, 15.6068f, 16.3934f, 16.8919f, 17.3913f, 17.9856f,
           18.4843f, 19.0114f, 19.4932f, 20.0803f, 20.7039f, 21.1864f, 21.692f, 22.2222f, 22.6757f, 23.4192f,
           23.6285f, 23.826f, 24.4186f, 24.947f, 25.53f, 26.1183f, 26.6583f, 27.2448f, 27.7783f, 28.9855f }},
        {{ 1.14995f, 1.20005f, 1.25f, 1.35007f, 1.39997f, 1.44991f, 1.54991f, 1.6f, 1.64989f, 1.75009f,
           1.95008f, 2.15008f, 2.39981f, 0.0f, 0.0f, 3.09981f, 3.30033f, 3.54988f, 3.79939f, 4.05022f,
           4.29923f, 4.50045f, 4.75059f, 4.9505f, 5.24934f, 5.50055f, 5.70125f, 5.94884f, 6.19963f, 6.50195f,
           6.69792f, 6.94927f, 7.19942f, 7.45156f, 7.75194f, 8.0f, 8.19672f, 8.45308f, 8.70322f, 9.0009f,
           9.25069f, 9.49668f, 9.74659f, 10.0503f, 10.352f, 10.6045f, 10.846f, 11.0988f, 11.3507f, 11.6959f,
           11.9474f, 12.1951f, 12.5f, 12.7551f, 13.0548f, 13.3511f, 13.6054f, 13.9082f, 14.1443f, 14.4928f }}
    },
    {
        CLASS_PRIEST,
        {{ 10.0f, 10.0f, 0.0f, 10.5042f, 10.5042f, 10.5042f, 10.5042f, 11.0011f, 11.0011f, 11.0011f,
           11.0011f, 11.4943f, 11.4943f, 11.4943f, 11.4943f, 12.0048f, 12.0048f, 0.0f, 12.5f, 12.5f,
           12.5f, 12.5f, 0.0f, 13.0039f, 13.0039f, 13.4953f, 13.4953f, 13.4953f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 20.0f }},
        {{ 10.0f, 10.0f, 0.0f, 10.5042f, 10.5042f, 10.5042f, 10.5042f, 11.0011f, 11.0011f, 11.0011f,
           11.0011f, 11.4943f, 11.4943f, 11.4943f, 11.4943f, 12.0048f, 12.0048f, 0.0f, 12.5f, 12.5f,
           12.5f, 12.5f, 0.0f, 13.0039f, 13.0039f, 13.4953f, 13.4953f, 13.4953f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 17.5131f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 20.0f }}
    },
    {
        CLASS_SHAMAN,
        {{ 6.06061f, 6.06061f, 6.36537f, 6.36537f, 6.66667f, 6.66667f, 6.66667f, 6.96864f, 6.96864f, 7.27273f,
           7.27273f, 7.57576f, 7.57576f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           9.23551f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 15.748f, 16.0514f, 16.0514f, 16.6667f,
           16.9779f, 17.2712f, 17.2712f, 17.5747f, 18.1818f, 18.4843f, 18.797f, 18.797f, 19.084f, 19.685f }},
        {{ 6.06061f, 6.06061f, 6.36537f, 6.36537f, 6.66667f, 6.66667f, 6.66667f, 6.96864f, 6.96864f, 7.27273f,
           7.27273f, 7.57576f, 7.57576f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           9.38967f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f,
           0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 15.748f, 16.0514f, 16.0514f, 16.6667f,
           16.9779f, 17.2712f, 17.2712f, 17.5747f, 18.1818f, 18.4843f, 18.797f, 18.797f, 19.084f, 19.685f }}
    },
    {
        CLASS_MAGE,
        {{ 11.1111f, 11.1111f, 11.1111f, 11.6686f, 11.6686f, 11.6686f, 11.6686f, 11.6686f, 11.6686f, 12.2249f,
           12.2249f, 12.2249f, 12.2249f, 12.2249f, 12.7714f, 12.7714f, 12.7714f, 12.7714f, 12.7714f, 13.3333f,
           13.3333f, 13.3333f, 13.3333f, 13.8889f, 13.8889f, 13.8889f, 13.8889f, 13.8889f, 14.4509f, 14.4509f,
           14.4509f, 14.4509f, 14.9925f, 14.9925f, 14.9925f, 15.5521f, 15.5521f, 15.5521f, 15.5521f, 16.1031f,
           16.1031f, 16.1031f, 16.1031f, 16.6667f, 16.6667f, 16.6667f, 17.2117f, 17.2117f, 17.2117f, 17.762f,
           17.762f, 17.762f, 18.3486f, 18.3486f, 18.3486f, 18.9036f, 18.9036f, 18.9036f, 19.4553f, 19.4553f }},
        {{ 11.1111f, 11.1111f, 11.1111f, 11.6686f, 11.6686f, 11.6686f, 11.6686f, 11.6686f, 11.6686f, 12.2249f,
           12.2249f, 12.2249f, 12.2249f, 12.2249f, 12.7714f, 12.7714f, 12.7714f, 12.7714f, 12.7714f, 13.3333f,
           13.3333f, 13.3333f, 13.3333f, 13.8889f, 13.8889f, 13.8889f, 13.8889f, 13.8889f, 14.4509f, 14.4509f,
           14.4509f, 14.4509f, 14.9925f, 14.9925f, 14.9925f, 15.5521f, 15.5521f, 15.5521f, 15.5521f, 16.1031f,
           16.1031f, 16.1031f, 16.1031f, 16.6667f, 16.6667f, 16.6667f, 17.2117f, 17.2117f, 17.2117f, 17.762f,
           17.762f, 17.762f, 18.3486f, 18.3486f, 18.3486f, 18.9036f, 18.9036f, 18.9036f, 19.4553f, 19.4553f }}
    },
    {
        CLASS_WARLOCK,
        {{ 6.66667f, 6.66667f, 6.9979f, 6.9979f, 6.9979f, 7.33138f, 7.33138f, 7.33138f, 7.66871f, 7.66871f,
           8.0f, 8.0f, 8.0f, 8.33333f, 8.66551f, 9.0009f, 9.0009f, 9.0009f, 9.33707f, 9.67118f,
           10.0f, 10.0f, 10.3306f, 10.3306f, 11.0011f, 11.0011f, 11.0011f, 11.3379f, 11.3379f, 12.0048f,
           12.0048f, 12.3305f, 12.3305f, 12.6743f, 13.0039f, 13.3333f, 13.6612f, 13.6612f, 14.0056f, 14.3266f,
           14.6628f, 14.6628f, 14.9925f, 14.9925f, 15.674f, 16.0f, 16.0f, 16.3399f, 16.6667f, 17.0068f,
           17.331f, 17.331f, 17.6678f, 17.9856f, 18.3486f, 18.6567f, 19.0114f, 19.3424f, 19.3424f, 20.0f }},
        {{ 6.66667f, 6.66667f, 6.9979f, 6.9979f, 6.9979f, 7.33138f, 7.33138f, 7.33138f, 7.66871f, 7.66871f,
           8.0f, 8.0f, 8.0f, 8.33333f, 8.66551f, 9.0009f, 9.0009f, 9.0009f, 9.33707f, 9.67118f,
           10.0f, 10.0f, 10.3306f, 10.3306f, 11.0011f, 11.0011f, 11.0011f, 11.3379f, 11.3379f, 12.0048f,
           12.0048f, 12.3305f, 12.3305f, 12.6743f, 13.0039f, 13.3333f, 13.6612f, 13.6612f, 14.0056f, 14.3266f,
           14.6628f, 14.6628f, 14.9925f, 14.9925f, 15.674f, 16.0f, 16.0f, 16.3399f, 16.6667f, 17.0068f,
           17.331f, 17.331f, 17.6678f, 17.9856f, 18.3486f, 18.6567f, 19.0114f, 19.3424f, 19.3424f, 20.0f }}
    },
    {
        CLASS_DRUID,
        {{ 4.87805f, 4.87805f, 5.12295f, 5.12295f, 5.36481f, 5.36481f, 5.60853f, 5.60853f, 5.8548f, 6.34115f,
           6.58328f, 6.58328f, 6.8306f, 6.8306f, 7.31529f, 7.31529f, 7.55858f, 7.8064f, 7.8064f, 8.77963f,
           8.77963f, 9.02527f, 9.26784f, 9.26784f, 9.7561f, 9.7561f, 10.0f, 10.2459f, 10.2459f, 11.2233f,
           11.4679f, 11.4679f, 11.7096f, 11.9474f, 12.1951f, 12.4378f, 12.6904f, 12.6904f, 12.9199f, 13.9082f,
           0.0f, 14.1443f, 14.3885f, 14.6413f, 15.1286f, 15.361f, 15.361f, 15.6006f, 15.8479f, 16.835f,
           17.0648f, 17.331f, 17.5747f, 17.5747f, 18.0505f, 18.2815f, 18.5529f, 18.797f, 19.0114f, 20.0f }},
        {{ 4.87805f, 4.87805f, 5.12295f, 5.12295f, 5.36481f, 5.36481f, 5.60853f, 5.60853f, 5.8548f, 6.34115f,
           6.58328f, 6.58328f, 6.8306f, 6.8306f, 7.31529f, 7.31529f, 7.55858f, 7.8064f, 7.8064f, 8.77963f,
           8.77963f, 9.02527f, 9.26784f, 9.26784f, 9.7561f, 9.7561f, 10.0f, 10.2459f, 10.2459f, 11.2233f,
           11.4679f, 11.4679f, 11.7096f, 11.9474f, 12.1951f, 12.4378f, 12.6904f, 12.6904f, 12.9199f, 13.9082f,
           0.0f, 14.1443f, 14.3885f, 14.6413f, 15.1286f, 15.361f, 15.361f, 15.6006f, 15.8479f, 16.835f,
           17.0648f, 17.331f, 17.5747f, 17.5747f, 18.0505f, 18.2815f, 18.5529f, 18.797f, 19.0114f, 20.0f }}
    }
}};

constexpr float InterpolatedRate(LevelRates const& rates, uint8 level)
{
    std::size_t const index = std::clamp<std::size_t>(level, 1, VanillaMaxLevel) - 1;
    if (rates[index] > 0.0f)
        return rates[index];

    std::size_t previous = index;
    while (rates[previous] <= 0.0f)
        --previous;
    std::size_t next = index;
    while (rates[next] <= 0.0f)
        ++next;
    return rates[previous] + (rates[next] - rates[previous]) * float(index - previous) / float(next - previous);
}

constexpr AgilityRates const* FindAgilityRates(uint32 playerClass)
{
    for (AgilityRates const& rates : SniffedAgilityRates)
        if (rates.Class == playerClass)
            return &rates;
    return nullptr;
}

constexpr float AgilityPerMeleeCrit(uint32 playerClass, uint8 level)
{
    AgilityRates const* rates = FindAgilityRates(playerClass);
    return rates ? InterpolatedRate(rates->AgilityPerCrit, level) : 0.0f;
}

constexpr float AgilityPerDodge(uint32 playerClass, uint8 level)
{
    AgilityRates const* rates = FindAgilityRates(playerClass);
    return rates ? InterpolatedRate(rates->AgilityPerDodge, level) : 0.0f;
}

constexpr float VanillaClassBasePct(uint32 playerClass)
{
    switch (playerClass)
    {
        case CLASS_PALADIN: return 0.7f;
        case CLASS_PRIEST:  return 3.0f;
        case CLASS_SHAMAN:  return 1.7f;
        case CLASS_MAGE:    return 3.2f;
        case CLASS_WARLOCK: return 2.0f;
        case CLASS_DRUID:   return 0.9f;
        default:            return 0.0f;
    }
}

// Warrior and Druid keep the CoA client's base melee crit, which differs from stock 3.3.5.
constexpr bool UsesClientBaseMeleeCrit(uint32 playerClass)
{
    return playerClass == CLASS_WARRIOR || playerClass == CLASS_DRUID;
}

struct SpellCritRates
{
    float BasePct;
    float IntellectPerCrit;
    float IntellectPerCritPerLevel;
};

constexpr std::optional<SpellCritRates> VanillaSpellCritRates(uint32 playerClass)
{
    switch (playerClass)
    {
        case CLASS_PALADIN: return SpellCritRates{ 3.70f, 14.77f, 0.65f };
        case CLASS_PRIEST:  return SpellCritRates{ 2.97f, 10.03f, 0.82f };
        case CLASS_SHAMAN:  return SpellCritRates{ 3.54f, 11.51f, 0.80f };
        case CLASS_MAGE:    return SpellCritRates{ 3.70f, 14.77f, 0.65f };
        case CLASS_WARLOCK: return SpellCritRates{ 3.18f, 11.30f, 0.82f };
        case CLASS_DRUID:   return SpellCritRates{ 3.33f, 12.41f, 0.79f };
        default:            return std::nullopt;
    }
}

// The CoA client authored the base spell crit of Paladin, Shaman and Mage and the Druid intellect ratio,
// which differ from stock 3.3.5; those components keep the client values.
constexpr bool UsesClientBaseSpellCrit(uint32 playerClass)
{
    return playerClass == CLASS_PALADIN || playerClass == CLASS_SHAMAN || playerClass == CLASS_MAGE;
}

constexpr bool UsesClientSpellCritRatio(uint32 playerClass)
{
    return playerClass == CLASS_DRUID;
}

constexpr StatCurve MeleeCrit(uint32 playerClass, uint8 level, StatCurve client)
{
    if (!UsesVanillaFormulas(playerClass))
        return client;

    float const base = UsesClientBaseMeleeCrit(playerClass) ? client.Base : VanillaClassBasePct(playerClass) / 100.0f;
    float const perPoint = 0.01f / AgilityPerMeleeCrit(playerClass, level);
    return { Blend(base, client.Base, level), Blend(perPoint, client.PerPoint, level) };
}

constexpr StatCurve Dodge(uint32 playerClass, uint8 level, StatCurve current)
{
    if (!UsesVanillaFormulas(playerClass))
        return current;

    float const base = VanillaClassBasePct(playerClass) / 100.0f;
    float const perPoint = 0.01f / AgilityPerDodge(playerClass, level);
    return { Blend(base, current.Base, level), Blend(perPoint, current.PerPoint, level) };
}

constexpr StatCurve SpellCrit(uint32 playerClass, uint8 level, StatCurve client)
{
    std::optional<SpellCritRates> const rates = VanillaSpellCritRates(playerClass);
    if (!rates)
        return client;

    float const base = UsesClientBaseSpellCrit(playerClass) ? client.Base : rates->BasePct / 100.0f;
    float const vanillaLevel = float(std::min(level, VanillaMaxLevel));
    float const perPoint = UsesClientSpellCritRatio(playerClass) ? client.PerPoint :
        0.01f / (rates->IntellectPerCrit + rates->IntellectPerCritPerLevel * vanillaLevel);
    return { Blend(base, client.Base, level), Blend(perPoint, client.PerPoint, level) };
}

struct HealthRegenRates
{
    float PerSpirit;
    float Flat;
};

constexpr std::optional<HealthRegenRates> VanillaHealthRegenRates(uint32 playerClass)
{
    switch (playerClass)
    {
        case CLASS_WARRIOR: return HealthRegenRates{ 1.26f, -22.6f };
        case CLASS_PALADIN: return HealthRegenRates{ 0.25f, 0.0f };
        case CLASS_HUNTER:  return HealthRegenRates{ 0.43f, -5.5f };
        case CLASS_ROGUE:   return HealthRegenRates{ 0.84f, -13.0f };
        case CLASS_PRIEST:  return HealthRegenRates{ 0.15f, 1.4f };
        case CLASS_SHAMAN:  return HealthRegenRates{ 0.28f, -3.6f };
        case CLASS_MAGE:    return HealthRegenRates{ 0.11f, 1.0f };
        case CLASS_WARLOCK: return HealthRegenRates{ 0.12f, 1.5f };
        case CLASS_DRUID:   return HealthRegenRates{ 0.11f, 1.0f };
        default:            return std::nullopt;
    }
}

constexpr float HealthRegenPerTick(uint32 playerClass, uint8 level, float spirit, float current)
{
    std::optional<HealthRegenRates> const rates = VanillaHealthRegenRates(playerClass);
    if (!rates)
        return current;
    return Blend(std::max(0.0f, rates->PerSpirit * spirit + rates->Flat), current, level);
}

constexpr float SittingHealthRegenMultiplier(uint32 playerClass, uint8 level, float current)
{
    return UsesVanillaFormulas(playerClass) ? Blend(1.5f, current, level) : current;
}

constexpr float PolymorphHealthRegenFraction(uint32 playerClass, uint8 level, float current)
{
    return UsesVanillaFormulas(playerClass) ? Blend(0.1f, current, level) : current;
}

constexpr float MeleeAttackPower(uint32 playerClass, uint8 level, float strength, float current)
{
    if (playerClass != CLASS_SHAMAN)
        return current;
    return Blend(level * 2.0f + strength * 2.0f - 20.0f, current, level);
}
}

#endif
