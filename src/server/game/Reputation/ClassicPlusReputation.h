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

#ifndef ACORE_CLASSIC_PLUS_REPUTATION_H
#define ACORE_CLASSIC_PLUS_REPUTATION_H

#include "Define.h"
#include <array>

namespace ClassicPlusReputation
{
    constexpr uint8 MaxLevel = 60;

    struct SpilloverTarget
    {
        uint32 faction;
        float rate;
    };

    struct Spillover
    {
        uint32 faction;
        std::array<SpilloverTarget, 5> targets;
    };

    // vmangos reputation_spillover_template (1.12). Exodar and Silvermoon City join the vanilla capitals.
    constexpr std::array<Spillover, 13> Spillovers = { {
        { 47, {} }, { 54, {} }, { 68, {} }, { 69, {} }, { 72, {} }, { 76, {} }, { 81, {} }, { 530, {} },
        { 911, {} }, { 930, {} },
        { 67, { { { 68, 0.25f }, { 76, 0.25f }, { 81, 0.25f }, { 530, 0.25f }, { 911, 0.25f } } } },
        { 169, { { { 21, 1.0f }, { 369, 1.0f }, { 470, 1.0f }, { 577, 1.0f }, { 0, 0.0f } } } },
        { 469, { { { 47, 0.25f }, { 54, 0.25f }, { 69, 0.25f }, { 72, 0.25f }, { 930, 0.25f } } } },
    } };

    [[nodiscard]] constexpr Spillover const* Find(uint32 faction)
    {
        for (Spillover const& spillover : Spillovers)
            if (spillover.faction == faction)
                return &spillover;
        return nullptr;
    }
}

#endif
