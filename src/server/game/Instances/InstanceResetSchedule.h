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

#ifndef ACORE_INSTANCE_RESET_SCHEDULE_H
#define ACORE_INSTANCE_RESET_SCHEDULE_H

#include "AreaDefines.h"
#include "Common.h"
#include "DBCEnums.h"

namespace InstanceResetSchedule
{
    // The CoA client MapDifficulty.dbc has RaidDuration 0 on raids and heroic dungeons; its rows stay unmodified.
    [[nodiscard]] constexpr uint32 GetFallbackResetDelay(uint32 mapId, MapTypes mapType, Difficulty difficulty)
    {
        if (mapType == MAP_RAID)
            return mapId == MAP_ZUL_GURUB || mapId == MAP_RUINS_OF_AHN_QIRAJ || mapId == MAP_ZUL_AMAN ? 3 * DAY : WEEK;

        return mapType == MAP_INSTANCE && difficulty != DUNGEON_DIFFICULTY_NORMAL ? DAY : 0;
    }

    [[nodiscard]] constexpr uint32 GetResetDelay(uint32 dbcDelay, uint32 mapId, MapTypes mapType, Difficulty difficulty)
    {
        return dbcDelay ? dbcDelay : GetFallbackResetDelay(mapId, mapType, difficulty);
    }
}

#endif
