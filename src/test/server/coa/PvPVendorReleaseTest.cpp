#include "AscensionPvPVendorRelease.h"
#include <gtest/gtest.h>

using PvPVendorRelease::IsEventReleased;
using PvPVendorRelease::PhaseOneVendorsEvent;
using PvPVendorRelease::PhaseTwoVendorsEvent;

TEST(PvPVendorRelease, DefaultStageShowsOnlyPhaseOne)
{
    EXPECT_TRUE(IsEventReleased(PhaseOneVendorsEvent, PvPVendorRelease::DefaultStage));
    EXPECT_FALSE(IsEventReleased(PhaseTwoVendorsEvent, PvPVendorRelease::DefaultStage));
}

TEST(PvPVendorRelease, PhaseTwoStageShowsBothPhases)
{
    EXPECT_TRUE(IsEventReleased(PhaseOneVendorsEvent, PvPVendorRelease::StagePhaseTwo));
    EXPECT_TRUE(IsEventReleased(PhaseTwoVendorsEvent, PvPVendorRelease::StagePhaseTwo));
}

TEST(PvPVendorRelease, PhaseOneStageHoldsBackPhaseTwoVendors)
{
    EXPECT_TRUE(IsEventReleased(PhaseOneVendorsEvent, PvPVendorRelease::StagePhaseOne));
    EXPECT_FALSE(IsEventReleased(PhaseTwoVendorsEvent, PvPVendorRelease::StagePhaseOne));
}

TEST(PvPVendorRelease, StageZeroShowsNoVendors)
{
    EXPECT_FALSE(IsEventReleased(PhaseOneVendorsEvent, 0));
    EXPECT_FALSE(IsEventReleased(PhaseTwoVendorsEvent, 0));
}

TEST(PvPVendorRelease, StagesBeyondPhaseTwoKeepEveryPhase)
{
    EXPECT_TRUE(IsEventReleased(PhaseOneVendorsEvent, 9));
    EXPECT_TRUE(IsEventReleased(PhaseTwoVendorsEvent, 9));
}

TEST(PvPVendorRelease, UnrelatedEventsAreNeverStarted)
{
    EXPECT_FALSE(IsEventReleased(195, PvPVendorRelease::DefaultStage));
    EXPECT_FALSE(IsEventReleased(196, PvPVendorRelease::DefaultStage));
}
