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

#ifndef __GAMETIME_H
#define __GAMETIME_H

#include "Define.h"
#include "Duration.h"

namespace GameTime
{
    // Server start time
    AC_GAME_API Seconds GetStartTime();

    // Current server time (unix)
    AC_GAME_API Seconds GetGameTime();

    // Milliseconds since server start
    AC_GAME_API Milliseconds GetGameTimeMS();

    /// Current chrono system_clock time point
    AC_GAME_API SystemTimePoint GetSystemTime();

    /// Current chrono steady_clock time point
    AC_GAME_API TimePoint Now();

    /// Uptime
    AC_GAME_API Seconds GetUptime();

    /// Uptime since a given time point
    inline Microseconds Elapsed(TimePoint start)
    {
        return std::chrono::duration_cast<Microseconds>(Now() - start);
    }

    /// Check if a duration has elapsed since a given time point
    template<class T>
    inline bool HasElapsed(TimePoint start, T duration)
    {
        return (Now() - start) >= duration;
    }

    /// Update all timers
    void UpdateGameTimers();

    AC_GAME_API void EnableSimulation();

    /// Tests and shutdown only: getMSTime() and the game clock return to real time and can move backwards
    AC_GAME_API void DisableSimulation();

    AC_GAME_API bool IsSimulated();

    AC_GAME_API void RequestStep(Milliseconds step);

    AC_GAME_API Milliseconds TakeStep(Milliseconds realElapsed, Milliseconds minimumPaced);

    /// Before the first simulated step only: that step starts the game's system clock here (never before the real
    /// system clock) instead of at the real system time; the steady clock keeps its real anchor
    AC_GAME_API void SetSimulatedSystemAnchor(SystemTimePoint anchor);

    /// Simulation only: the next step also moves every game clock forward by the jump, which the world update
    /// never receives as part of its diff
    AC_GAME_API void AdvanceSimulation(Milliseconds jump);

    /// Live steady clock, unlike the per-tick Now(); follows the simulated clock while simulation runs
    AC_GAME_API TimePoint SteadyNow();

    /// Time that calendar schedules such as quest resets count from: the real clock, or the game time while
    /// simulation runs, because the simulated game clock can run days ahead of the real one
    AC_GAME_API Seconds GetCalendarTime();
}

#endif
