/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayClock.h"
#include "gtest/gtest.h"
#include <vector>

using namespace CoAGameplay;
using namespace std::chrono_literals;

namespace
{
std::optional<Milliseconds> Choose(std::vector<StepRequest> const& requests, ClockPolicy const& policy = {})
{
    return ChooseStep(requests, policy);
}

StepRequest Lane(LaneActivity activity, Milliseconds remaining = 0ms, Milliseconds caseCap = 0ms,
    bool databaseQuiet = true)
{
    return StepRequest{activity, remaining, caseCap, databaseQuiet};
}
}

TEST(CoAGameplayClockTest, DefaultPolicyMatchesTheHarnessDefaults)
{
    ClockPolicy const policy;
    EXPECT_EQ(policy.step, 3ms);
    EXPECT_EQ(policy.activeWaitCap, 25ms);
    EXPECT_EQ(policy.pollCap, 10ms);
}

TEST(CoAGameplayClockTest, RunsPacedWhenNoLaneConstrainsTheClock)
{
    EXPECT_FALSE(Choose({}).has_value());
    EXPECT_FALSE(Choose({Lane(LaneActivity::Unconstrained)}).has_value());
    EXPECT_FALSE(Choose({Lane(LaneActivity::Unconstrained, 0ms, 0ms, false)}).has_value());
    EXPECT_FALSE(Choose({Lane(LaneActivity::Unconstrained, 500ms, 5ms), Lane(LaneActivity::Unconstrained)})
        .has_value());
}

TEST(CoAGameplayClockTest, SteppingLaneUsesTheStep)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping, 900ms)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping)}, ClockPolicy{7ms, 25ms, 10ms}), 7ms);
}

TEST(CoAGameplayClockTest, WaitingLandsExactlyOnTheRemainingTimeUnderTheCap)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 7ms)}), 7ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 25ms)}), 25ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 26ms)}), 25ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 30000ms)}), 25ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 1ms)}), 1ms);
}

TEST(CoAGameplayClockTest, FinishedWaitFallsBackToTheStep)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 0ms)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, -40ms)}), 3ms);
}

TEST(CoAGameplayClockTest, PollingUsesTheRemainingWindowUnderThePollCap)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 4ms)}), 4ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 10ms)}), 10ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 4000ms)}), 10ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 0ms)}), 1ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, -5ms)}), 1ms);
}

TEST(CoAGameplayClockTest, PendingDatabaseWorkHoldsAConstrainedLaneToTheStep)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 20000ms, 0ms, false)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 0ms, 0ms, false)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 9ms, 0ms, false)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping, 0ms, 0ms, false)}), 3ms);
}

TEST(CoAGameplayClockTest, PendingDatabaseWorkNeverStretchesAShorterConstraint)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 2ms, 0ms, false)}), 2ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 1ms, 0ms, false)}), 1ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 60000ms, 0ms, false)}, ClockPolicy{3ms, 2ms, 10ms}), 2ms);
}

TEST(CoAGameplayClockTest, CaseCapBoundsEveryConstrainedActivity)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 20000ms, 5ms)}), 5ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 20000ms, 0ms)}), 25ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 4ms, 5ms)}), 4ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Polling, 900ms, 2ms)}), 2ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping, 0ms, 1ms)}), 1ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 900ms, 2ms, false)}), 2ms);
}

TEST(CoAGameplayClockTest, ChoosesTheSmallestConstraintAcrossLanes)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 30000ms), Lane(LaneActivity::Polling, 8ms),
        Lane(LaneActivity::Unconstrained)}), 8ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 2ms), Lane(LaneActivity::Stepping)}), 2ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 30000ms), Lane(LaneActivity::Stepping)}), 3ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Unconstrained), Lane(LaneActivity::Waiting, 12ms)}), 12ms);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 30000ms), Lane(LaneActivity::Waiting, 30000ms, 0ms, false)}), 3ms);
}

TEST(CoAGameplayClockTest, ClampsTheChosenStepToTheSupportedRange)
{
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping)}, ClockPolicy{0ms, 25ms, 10ms}), MinimumStep);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 0ms)}, ClockPolicy{0ms, 25ms, 10ms}), MinimumStep);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 60000ms)}, ClockPolicy{3ms, 10000ms, 10ms}), MaximumStep);
    EXPECT_EQ(Choose({Lane(LaneActivity::Stepping)}, ClockPolicy{5000ms, 25ms, 10ms}), MaximumStep);
    EXPECT_EQ(Choose({Lane(LaneActivity::Waiting, 5ms)}, ClockPolicy{3ms, 0ms, 10ms}), MinimumStep);
    EXPECT_EQ(MinimumStep, 1ms);
    EXPECT_EQ(MaximumStep, 2000ms);
}
