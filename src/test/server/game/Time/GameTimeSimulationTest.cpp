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

#include "GameTime.h"
#include "Timer.h"
#include "gtest/gtest.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <limits>
#include <thread>

namespace
{
    constexpr Milliseconds LargestStep = 2000ms;

    uint32 RealMSTime()
    {
        return uint32(GetTimeMS().count());
    }

    class GameTimeSimulationTest : public ::testing::Test
    {
    protected:
        void SetUp() override
        {
            GameTime::DisableSimulation();
        }

        void TearDown() override
        {
            GameTime::DisableSimulation();
        }

        static void StartSimulation()
        {
            GameTime::UpdateGameTimers();
            GameTime::EnableSimulation();
            EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
            GameTime::UpdateGameTimers();
        }

        static void Advance(Milliseconds step)
        {
            GameTime::RequestStep(step);
            EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), step);
            GameTime::UpdateGameTimers();
        }

        static void AdvanceBy(Milliseconds total)
        {
            while (total > 0ms)
            {
                Milliseconds const step = std::min(total, LargestStep);
                Advance(step);
                total -= step;
            }
        }
    };
}

TEST_F(GameTimeSimulationTest, AnchoringNeverMovesTheClockBackwards)
{
    GameTime::UpdateGameTimers();
    uint32 const msTimeBefore = getMSTime();
    Milliseconds const gameMSTimeBefore = GameTime::GetGameTimeMS();
    TimePoint const nowBefore = GameTime::Now();
    SystemTimePoint const systemTimeBefore = GameTime::GetSystemTime();

    GameTime::EnableSimulation();
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
    uint32 const anchoredMSTime = getMSTime();
    EXPECT_GE(anchoredMSTime, msTimeBefore);

    std::this_thread::sleep_for(5ms);
    EXPECT_EQ(getMSTime(), anchoredMSTime);

    GameTime::UpdateGameTimers();
    EXPECT_EQ(getMSTime(), anchoredMSTime);
    EXPECT_GE(getMSTime(), msTimeBefore);
    EXPECT_GE(GameTime::GetGameTimeMS(), gameMSTimeBefore);
    EXPECT_GE(GameTime::Now(), nowBefore);
    EXPECT_GE(GameTime::GetSystemTime(), systemTimeBefore);
}

TEST_F(GameTimeSimulationTest, AnchoringStartsEveryGameClockAtTheRealClock)
{
    GameTime::EnableSimulation();
    TimePoint const steadyBefore = std::chrono::steady_clock::now();
    SystemTimePoint const systemBefore = std::chrono::system_clock::now();
    uint32 const realMSTimeBefore = RealMSTime();
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
    TimePoint const steadyAfter = std::chrono::steady_clock::now();
    SystemTimePoint const systemAfter = std::chrono::system_clock::now();
    uint32 const realMSTimeAfter = RealMSTime();

    std::this_thread::sleep_for(5ms);
    GameTime::UpdateGameTimers();

    EXPECT_GE(GameTime::Now(), steadyBefore);
    EXPECT_LE(GameTime::Now(), steadyAfter);
    EXPECT_GE(GameTime::GetSystemTime(), systemBefore);
    EXPECT_LE(GameTime::GetSystemTime(), systemAfter);
    EXPECT_EQ(GameTime::GetGameTime(),
        std::chrono::duration_cast<Seconds>(GameTime::GetSystemTime().time_since_epoch()));
    EXPECT_GE(GameTime::GetGameTimeMS(), Milliseconds(realMSTimeBefore));
    EXPECT_LE(GameTime::GetGameTimeMS(), Milliseconds(realMSTimeAfter));
}

TEST_F(GameTimeSimulationTest, ArmedClockStaysRealUntilTheFirstStep)
{
    GameTime::EnableSimulation();
    EXPECT_TRUE(GameTime::IsSimulated());
    EXPECT_EQ(Acore::Time::SimulatedMSTime.load(), -1);

    TimePoint const steadyBefore = std::chrono::steady_clock::now();
    TimePoint const steadyNow = GameTime::SteadyNow();
    EXPECT_GE(steadyNow, steadyBefore);
    EXPECT_LE(steadyNow, std::chrono::steady_clock::now());

    uint32 const realBefore = RealMSTime();
    GameTime::UpdateGameTimers();
    EXPECT_GE(GameTime::GetGameTimeMS(), Milliseconds(realBefore));
    EXPECT_LE(GameTime::GetGameTimeMS(), Milliseconds(RealMSTime()));
}

TEST_F(GameTimeSimulationTest, ClockIsFrozenBetweenSteps)
{
    StartSimulation();
    uint32 const msTime = getMSTime();
    TimePoint const now = GameTime::Now();
    TimePoint const steadyNow = GameTime::SteadyNow();

    std::this_thread::sleep_for(20ms);
    GameTime::UpdateGameTimers();

    EXPECT_EQ(getMSTime(), msTime);
    EXPECT_EQ(GameTime::Now(), now);
    EXPECT_EQ(GameTime::SteadyNow(), steadyNow);
}

TEST_F(GameTimeSimulationTest, EveryStepAdvancesTheClockByExactlyTheStep)
{
    StartSimulation();
    for (int i = 0; i < 200; ++i)
    {
        Milliseconds const step(1 + i % 25);
        uint32 const msTimeBefore = getMSTime();
        Milliseconds const gameMSTimeBefore = GameTime::GetGameTimeMS();
        TimePoint const nowBefore = GameTime::Now();

        Advance(step);

        EXPECT_EQ(getMSTime() - msTimeBefore, uint32(step.count()));
        EXPECT_EQ(GameTime::GetGameTimeMS() - gameMSTimeBefore, step);
        EXPECT_EQ(GameTime::Now() - nowBefore, step);
    }
}

TEST_F(GameTimeSimulationTest, AllGameClocksAgreeAfterAFastForward)
{
    StartSimulation();
    TimePoint const steadyStart = GameTime::Now();
    SystemTimePoint const systemStart = GameTime::GetSystemTime();
    Milliseconds const gameMSTimeStart = GameTime::GetGameTimeMS();
    uint32 const msTimeStart = getMSTime();
    Seconds const uptimeStart = GameTime::GetUptime();
    Milliseconds const elapsed = 10min;

    AdvanceBy(elapsed);

    EXPECT_EQ(GameTime::Now() - steadyStart, elapsed);
    EXPECT_EQ(GameTime::GetSystemTime() - systemStart, elapsed);
    EXPECT_EQ(GameTime::GetGameTimeMS() - gameMSTimeStart, elapsed);
    EXPECT_EQ(getMSTime() - msTimeStart, uint32(elapsed.count()));
    EXPECT_EQ(GameTime::GetGameTimeMS(),
        std::chrono::duration_cast<Milliseconds>(GameTime::Now() - GetApplicationStartTime()));
    EXPECT_EQ(getMSTime(), uint32(GameTime::GetGameTimeMS().count()));
    EXPECT_EQ(GameTime::GetGameTime(),
        std::chrono::duration_cast<Seconds>(GameTime::GetSystemTime().time_since_epoch()));
    EXPECT_EQ(GameTime::GetUptime() - uptimeStart, std::chrono::duration_cast<Seconds>(elapsed));
    EXPECT_GE(GameTime::GetSystemTime() - std::chrono::system_clock::now(), elapsed - 1min);
    EXPECT_LE(GameTime::GetSystemTime() - std::chrono::system_clock::now(), elapsed);
    EXPECT_GE(GameTime::Now() - std::chrono::steady_clock::now(), elapsed - 1min);
    EXPECT_LE(GameTime::Now() - std::chrono::steady_clock::now(), elapsed);
}

TEST_F(GameTimeSimulationTest, MSTimeFollowsTheGameClockOnlyWhileSimulated)
{
    uint32 const realBefore = RealMSTime();
    uint32 const msTimeOff = getMSTime();
    EXPECT_GE(msTimeOff, realBefore);
    EXPECT_LE(msTimeOff, RealMSTime());

    StartSimulation();
    AdvanceBy(1min);
    EXPECT_EQ(getMSTime(), uint32(GameTime::GetGameTimeMS().count()));
    EXPECT_GE(getMSTime() - RealMSTime(), 59000u);

    GameTime::DisableSimulation();
    uint32 const realAfterDisable = RealMSTime();
    uint32 const msTimeAfterDisable = getMSTime();
    EXPECT_GE(msTimeAfterDisable, realAfterDisable);
    EXPECT_LE(msTimeAfterDisable, RealMSTime());
}

TEST_F(GameTimeSimulationTest, SteadyNowIsLiveAndFollowsTheSimulatedClock)
{
    TimePoint const steadyBefore = std::chrono::steady_clock::now();
    TimePoint const steadyNowOff = GameTime::SteadyNow();
    EXPECT_GE(steadyNowOff, steadyBefore);
    EXPECT_LE(steadyNowOff, std::chrono::steady_clock::now());

    StartSimulation();
    EXPECT_EQ(GameTime::SteadyNow(), GameTime::Now());

    GameTime::RequestStep(40ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 40ms);
    EXPECT_EQ(GameTime::SteadyNow() - GameTime::Now(), 40ms);

    GameTime::UpdateGameTimers();
    EXPECT_EQ(GameTime::SteadyNow(), GameTime::Now());
}

TEST_F(GameTimeSimulationTest, ProcCooldownExpiresOnTheSimulatedClock)
{
    StartSimulation();
    TimePoint const cooldownEnd = GameTime::SteadyNow() + 45s;

    AdvanceBy(45s - 1ms);
    EXPECT_GT(cooldownEnd, GameTime::SteadyNow());

    Advance(1ms);
    EXPECT_FALSE(cooldownEnd > GameTime::SteadyNow());
}

TEST_F(GameTimeSimulationTest, UnrequestedStepsArePacedByRealTime)
{
    StartSimulation();
    TimePoint const start = GameTime::SteadyNow();

    EXPECT_EQ(GameTime::TakeStep(4ms, 5ms), 0ms);
    EXPECT_EQ(GameTime::SteadyNow(), start);

    EXPECT_EQ(GameTime::TakeStep(5ms, 5ms), 5ms);
    EXPECT_EQ(GameTime::SteadyNow() - start, 5ms);

    EXPECT_EQ(GameTime::TakeStep(2500ms, 5ms), 2500ms);
    EXPECT_EQ(GameTime::SteadyNow() - start, 2505ms);
}

TEST_F(GameTimeSimulationTest, RequestedStepIgnoresRealElapsedTime)
{
    StartSimulation();

    GameTime::RequestStep(3ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 10ms), 3ms);

    GameTime::RequestStep(3ms);
    EXPECT_EQ(GameTime::TakeStep(700ms, 10ms), 3ms);
}

TEST_F(GameTimeSimulationTest, SmallestRequestOfATickWinsAndIsConsumed)
{
    StartSimulation();

    GameTime::RequestStep(25ms);
    GameTime::RequestStep(3ms);
    GameTime::RequestStep(10ms);
    EXPECT_EQ(GameTime::TakeStep(100ms, 1ms), 3ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
}

TEST_F(GameTimeSimulationTest, RequestedStepsAreClamped)
{
    StartSimulation();

    GameTime::RequestStep(5000ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), LargestStep);

    GameTime::RequestStep(0ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 1ms);

    GameTime::RequestStep(-7ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 1ms);
}

TEST_F(GameTimeSimulationTest, RequestsNeverCarryIntoALaterSimulation)
{
    GameTime::RequestStep(7ms);
    GameTime::EnableSimulation();
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);

    GameTime::RequestStep(9ms);
    GameTime::DisableSimulation();
    GameTime::EnableSimulation();
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
}

TEST_F(GameTimeSimulationTest, EnablingAgainKeepsTheRunningClock)
{
    StartSimulation();
    AdvanceBy(10s);
    TimePoint const now = GameTime::Now();

    GameTime::EnableSimulation();
    Advance(1ms);

    EXPECT_EQ(GameTime::Now() - now, 1ms);
}

TEST_F(GameTimeSimulationTest, DisableSimulationRestoresTheRealClock)
{
    StartSimulation();
    AdvanceBy(1min);

    uint32 const realBefore = RealMSTime();
    TimePoint const steadyBefore = std::chrono::steady_clock::now();
    GameTime::DisableSimulation();
    TimePoint const steadyAfter = std::chrono::steady_clock::now();
    uint32 const realAfter = RealMSTime();

    EXPECT_FALSE(GameTime::IsSimulated());
    EXPECT_EQ(Acore::Time::SimulatedMSTime.load(), -1);
    EXPECT_GE(GameTime::GetGameTimeMS(), Milliseconds(realBefore));
    EXPECT_LE(GameTime::GetGameTimeMS(), Milliseconds(realAfter));
    EXPECT_GE(GameTime::Now(), steadyBefore);
    EXPECT_LE(GameTime::Now(), steadyAfter);
    EXPECT_GE(GameTime::SteadyNow(), steadyAfter);
    EXPECT_GE(getMSTime(), realAfter);
    EXPECT_LE(getMSTime(), RealMSTime());

    EXPECT_EQ(GameTime::TakeStep(3ms, 5ms), 0ms);
    EXPECT_EQ(GameTime::TakeStep(7ms, 5ms), 7ms);
    EXPECT_FALSE(GameTime::IsSimulated());

    uint32 const realBeforeRestart = RealMSTime();
    StartSimulation();
    EXPECT_GE(getMSTime(), realBeforeRestart);
    EXPECT_LE(getMSTime(), RealMSTime());
}

TEST_F(GameTimeSimulationTest, SimulatedMSTimeWrapsLikeTheRealClock)
{
    uint32 constexpr maxMSTime = std::numeric_limits<uint32>::max();

    Acore::Time::SimulatedMSTime.store(int64(maxMSTime) + 6);
    EXPECT_EQ(getMSTime(), 5u);
    EXPECT_EQ(getMSTimeDiff(maxMSTime - 10, getMSTime()), 15u);
    EXPECT_EQ(GetMSTimeDiffToNow(maxMSTime - 10), 15u);

    Acore::Time::SimulatedMSTime.store(-1);
    uint32 const realBefore = RealMSTime();
    EXPECT_GE(getMSTime(), realBefore);
    EXPECT_LE(getMSTime(), RealMSTime());
}

TEST_F(GameTimeSimulationTest, SystemAnchorStartsTheGameCalendarThereAndKeepsTheSteadyClockReal)
{
    GameTime::UpdateGameTimers();
    uint32 const msTimeBefore = getMSTime();
    SystemTimePoint const anchor = std::chrono::time_point_cast<SystemTimePoint::duration>(
        std::chrono::system_clock::now() + 7h + 250ms);

    GameTime::EnableSimulation();
    GameTime::SetSimulatedSystemAnchor(anchor);
    TimePoint const steadyBefore = std::chrono::steady_clock::now();
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
    TimePoint const steadyAfter = std::chrono::steady_clock::now();
    GameTime::UpdateGameTimers();

    EXPECT_EQ(GameTime::GetSystemTime(), anchor);
    EXPECT_EQ(GameTime::GetGameTime(), std::chrono::duration_cast<Seconds>(anchor.time_since_epoch()));
    EXPECT_GE(GameTime::Now(), steadyBefore);
    EXPECT_LE(GameTime::Now(), steadyAfter);
    EXPECT_GE(getMSTime(), msTimeBefore);
    EXPECT_LE(getMSTime(), RealMSTime());

    Advance(10ms);
    AdvanceBy(10min);
    EXPECT_EQ(GameTime::GetSystemTime() - anchor, 10min + 10ms);
}

TEST_F(GameTimeSimulationTest, UptimeIgnoresSystemCalendarChanges)
{
    GameTime::UpdateGameTimers();
    TimePoint const realStart = std::chrono::steady_clock::now();
    Seconds const before = GameTime::GetUptime();
    GameTime::EnableSimulation();
    GameTime::SetSimulatedSystemAnchor(std::chrono::system_clock::now() + 7h);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
    GameTime::UpdateGameTimers();

    EXPECT_GE(GameTime::GetUptime(), before);
    EXPECT_LE(GameTime::GetUptime() - before,
        std::chrono::duration_cast<Seconds>(std::chrono::steady_clock::now() - realStart) + 1s);

    Seconds const anchored = GameTime::GetUptime();
    AdvanceBy(10s);
    EXPECT_EQ(GameTime::GetUptime() - anchored, 10s);

    GameTime::DisableSimulation();
    EXPECT_GE(GameTime::GetUptime(), before);
    EXPECT_LE(GameTime::GetUptime() - before,
        std::chrono::duration_cast<Seconds>(std::chrono::steady_clock::now() - realStart) + 1s);
}

TEST_F(GameTimeSimulationTest, SystemAnchorNeverStartsTheGameCalendarBeforeTheRealClock)
{
    GameTime::EnableSimulation();
    GameTime::SetSimulatedSystemAnchor(std::chrono::system_clock::now() - 3h);
    SystemTimePoint const systemBefore = std::chrono::system_clock::now();
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
    SystemTimePoint const systemAfter = std::chrono::system_clock::now();
    GameTime::UpdateGameTimers();

    EXPECT_GE(GameTime::GetSystemTime(), systemBefore);
    EXPECT_LE(GameTime::GetSystemTime(), systemAfter);
}

TEST_F(GameTimeSimulationTest, SystemAnchorOnlyAppliesBeforeTheFirstSimulatedStep)
{
    SystemTimePoint const anchor = std::chrono::system_clock::now() + 5h;
    GameTime::SetSimulatedSystemAnchor(anchor);
    EXPECT_FALSE(GameTime::IsSimulated());
    StartSimulation();
    EXPECT_LT(GameTime::GetSystemTime(), anchor - 4h);

    SystemTimePoint const running = GameTime::GetSystemTime();
    GameTime::SetSimulatedSystemAnchor(anchor);
    Advance(1ms);
    EXPECT_EQ(GameTime::GetSystemTime() - running, 1ms);

    GameTime::DisableSimulation();
    GameTime::EnableSimulation();
    GameTime::SetSimulatedSystemAnchor(anchor);
    GameTime::DisableSimulation();
    StartSimulation();
    EXPECT_LT(GameTime::GetSystemTime(), anchor - 4h);
}

TEST_F(GameTimeSimulationTest, AdvanceMovesEveryClockAtTheNextStepWithoutEnlargingTheStep)
{
    StartSimulation();
    TimePoint const steadyStart = GameTime::Now();
    SystemTimePoint const systemStart = GameTime::GetSystemTime();
    Milliseconds const gameMSTimeStart = GameTime::GetGameTimeMS();
    uint32 const msTimeStart = getMSTime();

    GameTime::AdvanceSimulation(14h);
    EXPECT_EQ(GameTime::SteadyNow(), steadyStart);
    GameTime::RequestStep(3ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 3ms);
    GameTime::UpdateGameTimers();

    Milliseconds const moved = 14h + 3ms;
    EXPECT_EQ(GameTime::Now() - steadyStart, moved);
    EXPECT_EQ(GameTime::GetSystemTime() - systemStart, moved);
    EXPECT_EQ(GameTime::GetGameTimeMS() - gameMSTimeStart, moved);
    EXPECT_EQ(getMSTime() - msTimeStart, uint32(moved.count()));
    EXPECT_EQ(GameTime::GetGameTime(),
        std::chrono::duration_cast<Seconds>(GameTime::GetSystemTime().time_since_epoch()));

    Advance(5ms);
    EXPECT_EQ(GameTime::Now() - steadyStart, moved + 5ms);
}

TEST_F(GameTimeSimulationTest, AdvanceWaitsForAStepThatIsTaken)
{
    StartSimulation();
    TimePoint const start = GameTime::SteadyNow();

    GameTime::AdvanceSimulation(2h);
    EXPECT_EQ(GameTime::TakeStep(1ms, 5ms), 0ms);
    EXPECT_EQ(GameTime::SteadyNow(), start);

    EXPECT_EQ(GameTime::TakeStep(6ms, 5ms), 6ms);
    EXPECT_EQ(GameTime::SteadyNow() - start, 2h + 6ms);
}

TEST_F(GameTimeSimulationTest, AdvanceAddsUpAndIgnoresBackwardJumps)
{
    StartSimulation();
    TimePoint const start = GameTime::SteadyNow();

    GameTime::AdvanceSimulation(1h);
    GameTime::AdvanceSimulation(30min);
    GameTime::AdvanceSimulation(0ms);
    GameTime::AdvanceSimulation(-2h);
    Advance(1ms);

    EXPECT_EQ(GameTime::SteadyNow() - start, 90min + 1ms);
}

TEST_F(GameTimeSimulationTest, AdvanceBeforeTheFirstStepFollowsTheAnchor)
{
    SystemTimePoint const anchor = std::chrono::time_point_cast<SystemTimePoint::duration>(
        std::chrono::system_clock::now() + 1h);
    GameTime::EnableSimulation();
    GameTime::SetSimulatedSystemAnchor(anchor);
    GameTime::AdvanceSimulation(3h);
    GameTime::RequestStep(2ms);
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 2ms);
    GameTime::UpdateGameTimers();

    EXPECT_EQ(GameTime::GetSystemTime(), anchor + 3h + 2ms);
}

TEST_F(GameTimeSimulationTest, AdvanceNeverCarriesIntoALaterSimulation)
{
    GameTime::AdvanceSimulation(6h);
    StartSimulation();
    TimePoint const start = GameTime::SteadyNow();
    Advance(1ms);
    EXPECT_EQ(GameTime::SteadyNow() - start, 1ms);

    GameTime::AdvanceSimulation(6h);
    GameTime::DisableSimulation();
    StartSimulation();
    TimePoint const restarted = GameTime::SteadyNow();
    Advance(1ms);
    EXPECT_EQ(GameTime::SteadyNow() - restarted, 1ms);
}

TEST_F(GameTimeSimulationTest, CalendarTimeIsTheRealClockOutsideSimulation)
{
    Seconds const before = GetEpochTime();
    Seconds const calendar = GameTime::GetCalendarTime();
    EXPECT_GE(calendar, before);
    EXPECT_LE(calendar, GetEpochTime());
}

TEST_F(GameTimeSimulationTest, ResetSchedulesFireOnceWhenTheSimulatedCalendarStartsWeeksAhead)
{
    using Schedule = time_t (*)(time_t);
    std::array<Schedule, 3> const schedules{
        [](time_t from) { return Acore::Time::GetNextTimeWithDayAndHour(-1, 6, from); },
        [](time_t from) { return Acore::Time::GetNextTimeWithDayAndHour(4, 6, from); },
        [](time_t from) { return Acore::Time::GetNextTimeWithMonthAndHour(-1, 6, from); }};
    std::array<Seconds, 3> nextResets{};
    for (std::size_t index = 0; index < schedules.size(); ++index)
        nextResets[index] = Seconds(schedules[index](GameTime::GetCalendarTime().count()));

    GameTime::EnableSimulation();
    GameTime::SetSimulatedSystemAnchor(std::chrono::system_clock::now() + std::chrono::days(40));
    EXPECT_EQ(GameTime::TakeStep(0ms, 1ms), 0ms);
    std::array<uint32, 3> resets{};
    for (int tick = 0; tick < 5; ++tick)
    {
        Advance(1s);
        for (std::size_t index = 0; index < schedules.size(); ++index)
        {
            if (GameTime::GetGameTime() <= nextResets[index])
                continue;
            ++resets[index];
            nextResets[index] = Seconds(schedules[index](GameTime::GetCalendarTime().count()));
        }
    }

    EXPECT_EQ(resets, (std::array<uint32, 3>{1, 1, 1}));
    for (Seconds const nextReset : nextResets)
        EXPECT_GT(nextReset, GameTime::GetGameTime());
}

TEST_F(GameTimeSimulationTest, OtherThreadsNeverSeeTheClockMoveBackwards)
{
    StartSimulation();
    std::atomic<bool> stop{false};
    std::atomic<uint32> backwardReads{0};
    std::atomic<uint32> reads{0};

    std::thread reader([&]
    {
        uint32 previous = getMSTime();
        while (!stop.load())
        {
            uint32 const current = getMSTime();
            if (current < previous)
                ++backwardReads;

            previous = current;
            ++reads;
        }
    });

    while (reads.load() == 0)
        std::this_thread::yield();

    for (int i = 0; i < 5000; ++i)
        Advance(Milliseconds(1 + i % 3));

    stop = true;
    reader.join();
    EXPECT_EQ(backwardReads.load(), 0u);
    EXPECT_EQ(getMSTime(), uint32(GameTime::GetGameTimeMS().count()));
}
