/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAGameplayTimeline.h"
#include "ObjectGuid.h"
#include "gtest/gtest.h"

using namespace CoAGameplay;

namespace
{
constexpr uint32 LucifronEntry = 12118;
constexpr uint32 ImpactSpell = 2105212;
constexpr uint32 OtherSpell = 975011;

ObjectGuid Player(uint32 low)
{
    return ObjectGuid::Create<HighGuid::Player>(low);
}

TimelineEvent Cast(uint64 absoluteMs, uint32 spell, ObjectGuid target = ObjectGuid::Empty)
{
    return TimelineEvent{absoluteMs, TimelineEventKind::Cast, ObjectGuid::Empty, target, LucifronEntry, spell, 0};
}

TimelineFilter CastOf(uint32 spell)
{
    TimelineFilter filter;
    filter.kind = TimelineEventKind::Cast;
    filter.spell = spell;
    return filter;
}
}

TEST(CoAGameplayTimeline, IgnoresEventsBeforeStart)
{
    Timeline timeline;
    EXPECT_FALSE(timeline.Started());
    timeline.Record(Cast(500, ImpactSpell));
    EXPECT_TRUE(timeline.Events().empty());
    timeline.Start(1000);
    timeline.Record(Cast(999, ImpactSpell));
    EXPECT_TRUE(timeline.Started());
    EXPECT_TRUE(timeline.Events().empty());
}

TEST(CoAGameplayTimeline, RecordStoresTimeRelativeToStart)
{
    Timeline timeline;
    timeline.Start(1000);
    timeline.Record(Cast(8300, ImpactSpell));
    ASSERT_EQ(timeline.Events().size(), 1u);
    EXPECT_EQ(timeline.Events()[0].atMs, 7300u);
}

TEST(CoAGameplayTimeline, CountFiltersByKindSpellAndSourceEntry)
{
    Timeline timeline;
    timeline.Start(0);
    for (uint64 at : {1000u, 2000u, 3000u})
        timeline.Record(Cast(at, ImpactSpell));
    timeline.Record(Cast(4000, OtherSpell));
    TimelineEvent aura = Cast(5000, ImpactSpell);
    aura.kind = TimelineEventKind::AuraApplied;
    timeline.Record(aura);
    TimelineEvent foreign = Cast(6000, ImpactSpell);
    foreign.sourceEntry = 999;
    timeline.Record(foreign);

    EXPECT_EQ(timeline.Count(CastOf(ImpactSpell)), 4u);
    TimelineFilter bySource = CastOf(ImpactSpell);
    bySource.sourceEntry = LucifronEntry;
    EXPECT_EQ(timeline.Count(bySource), 3u);
    EXPECT_EQ(timeline.Count(CastOf(OtherSpell)), 1u);
}

TEST(CoAGameplayTimeline, CountFiltersByValue)
{
    Timeline timeline;
    timeline.Start(0);
    TimelineEvent state{100, TimelineEventKind::BossState, ObjectGuid::Empty, ObjectGuid::Empty, LucifronEntry, 0, 3};
    timeline.Record(state);
    TimelineFilter filter;
    filter.kind = TimelineEventKind::BossState;
    filter.value = 3;
    EXPECT_EQ(timeline.Count(filter), 1u);
    filter.value = 4;
    EXPECT_EQ(timeline.Count(filter), 0u);
}

TEST(CoAGameplayTimeline, FirstMsIsRelativeToEngage)
{
    Timeline timeline;
    timeline.Start(1000);
    timeline.MarkEngaged(3000);
    timeline.Record(Cast(8300, ImpactSpell));
    EXPECT_EQ(timeline.FirstMs(CastOf(ImpactSpell)), std::optional<int64>(5300));
    EXPECT_FALSE(timeline.FirstMs(CastOf(OtherSpell)).has_value());
}

TEST(CoAGameplayTimeline, FirstMsIsNegativeBeforeEngage)
{
    Timeline timeline;
    timeline.Start(1000);
    timeline.Record(Cast(2000, ImpactSpell));
    timeline.MarkEngaged(3000);
    EXPECT_EQ(timeline.FirstMs(CastOf(ImpactSpell)), std::optional<int64>(-1000));
}

TEST(CoAGameplayTimeline, FirstMsFallsBackToStartWhenNeverEngaged)
{
    Timeline timeline;
    timeline.Start(1000);
    timeline.Record(Cast(8300, ImpactSpell));
    EXPECT_EQ(timeline.FirstMs(CastOf(ImpactSpell)), std::optional<int64>(7300));
}

TEST(CoAGameplayTimeline, MarkEngagedKeepsTheFirstEngage)
{
    Timeline timeline;
    timeline.Start(0);
    timeline.MarkEngaged(3000);
    timeline.MarkEngaged(9000);
    timeline.Record(Cast(8300, ImpactSpell));
    EXPECT_EQ(timeline.FirstMs(CastOf(ImpactSpell)), std::optional<int64>(5300));
}

TEST(CoAGameplayTimeline, IntervalsBetweenSuccessiveMatches)
{
    Timeline timeline;
    timeline.Start(0);
    timeline.Record(Cast(5300, ImpactSpell));
    timeline.Record(Cast(20400, ImpactSpell));
    timeline.Record(Cast(35500, ImpactSpell));
    EXPECT_EQ(timeline.Intervals(CastOf(ImpactSpell)), (std::vector<uint64>{15100, 15100}));
    EXPECT_TRUE(timeline.Intervals(CastOf(OtherSpell)).empty());
}

TEST(CoAGameplayTimeline, ExcludedTargetsDropMatches)
{
    Timeline timeline;
    timeline.Start(0);
    ObjectGuid const tank = Player(1);
    ObjectGuid const healer = Player(2);
    timeline.Record(Cast(1000, ImpactSpell, tank));
    timeline.Record(Cast(2000, ImpactSpell, healer));
    TimelineFilter filter = CastOf(ImpactSpell);
    filter.excludedTargets = {tank};
    EXPECT_EQ(timeline.Count(filter), 1u);
}

TEST(CoAGameplayTimeline, TargetsRestrictMatches)
{
    Timeline timeline;
    timeline.Start(0);
    ObjectGuid const tank = Player(1);
    ObjectGuid const healer = Player(2);
    timeline.Record(Cast(1000, ImpactSpell, tank));
    timeline.Record(Cast(2000, ImpactSpell, healer));
    TimelineFilter filter = CastOf(ImpactSpell);
    filter.targets = {healer};
    EXPECT_EQ(timeline.Count(filter), 1u);
    EXPECT_EQ(timeline.FirstMs(filter), std::optional<int64>(2000));
}

TEST(CoAGameplayTimeline, StartClearsPreviousEvents)
{
    Timeline timeline;
    timeline.Start(0);
    timeline.MarkEngaged(100);
    timeline.Record(Cast(500, ImpactSpell));
    timeline.Start(10000);
    EXPECT_TRUE(timeline.Events().empty());
    EXPECT_EQ(timeline.Count(CastOf(ImpactSpell)), 0u);
    timeline.Record(Cast(10500, ImpactSpell));
    EXPECT_EQ(timeline.FirstMs(CastOf(ImpactSpell)), std::optional<int64>(500));
}

TEST(CoAGameplayTimeline, RecorderIgnoresOtherInstances)
{
    EXPECT_FALSE(RecordsUnit(409, 7, 409, 8));
    EXPECT_TRUE(RecordsUnit(409, 7, 409, 7));
    EXPECT_FALSE(RecordsUnit(409, 7, 0, 0));
}
