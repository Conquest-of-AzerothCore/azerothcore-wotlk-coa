#include "AscensionHighRiskPolicy.h"
#include <gtest/gtest.h>

TEST(HighRiskQueue, OpenWorldHighRiskPlayersMustRestToQueue)
{
    EXPECT_TRUE(HighRisk::QueueBlocked(true, true, false, false));
    EXPECT_FALSE(HighRisk::QueueBlocked(true, true, true, false));
}

TEST(HighRiskQueue, OtherRulesetsInstancesAndBotsQueueFreely)
{
    EXPECT_FALSE(HighRisk::QueueBlocked(false, true, false, false));
    EXPECT_FALSE(HighRisk::QueueBlocked(true, false, false, false));
    EXPECT_FALSE(HighRisk::QueueBlocked(true, true, false, true));
}
