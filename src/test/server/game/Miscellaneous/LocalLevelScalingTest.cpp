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

#include "AscensionQuestScaling.h"
#include "LocalLevelScaling.h"
#include "gtest/gtest.h"

using LocalLevelScaling::CurveLevel;
using LocalLevelScaling::DungeonBandFromFinder;
using LocalLevelScaling::EffectiveQuestLevel;
using LocalLevelScaling::OnCurve;
using LocalLevelScaling::QuestCurve;
using LocalLevelScaling::LevelBand;
using LocalLevelScaling::MergeBands;
using LocalLevelScaling::ScaleCreatureLevelForViewer;
using LocalLevelScaling::ScaleDungeonCreatureLevelForViewer;

TEST(LocalLevelScalingTest, OpenWorldCreatureAboveViewerKeepsItsLevel)
{
    EXPECT_EQ(ScaleCreatureLevelForViewer(38, 20), 38);
}

TEST(LocalLevelScalingTest, OpenWorldCreatureIsLiftedToFourBelowTheViewer)
{
    EXPECT_EQ(ScaleCreatureLevelForViewer(5, 60), 56);
    EXPECT_EQ(ScaleCreatureLevelForViewer(5, 4), 5);
    EXPECT_EQ(ScaleCreatureLevelForViewer(1, 3), 1);
    EXPECT_EQ(ScaleCreatureLevelForViewer(5, 40, 3), 37);
}

TEST(LocalLevelScalingTest, DungeonCreatureStandsAtTheViewerLevelInsideTheBand)
{
    LevelBand const cathedral{ 20, 59 };
    EXPECT_EQ(ScaleDungeonCreatureLevelForViewer(20, cathedral), 20);
    EXPECT_EQ(ScaleDungeonCreatureLevelForViewer(33, cathedral), 33);
    EXPECT_EQ(ScaleDungeonCreatureLevelForViewer(15, cathedral), 20);
    EXPECT_EQ(ScaleDungeonCreatureLevelForViewer(60, cathedral), 59);
}

TEST(LocalLevelScalingTest, FinderPlaceholderLevelsFallBackToTheClassicRange)
{
    LevelBand const wailing = DungeonBandFromFinder(100, 100);
    EXPECT_EQ(wailing.Low, 15);
    EXPECT_EQ(wailing.High, 59);

    LevelBand const sunken = DungeonBandFromFinder(45, 59);
    EXPECT_EQ(sunken.Low, 45);
    EXPECT_EQ(sunken.High, 59);

    LevelBand const inverted = DungeonBandFromFinder(30, 20);
    EXPECT_EQ(inverted.Low, 30);
    EXPECT_EQ(inverted.High, 59);
}

TEST(LocalLevelScalingTest, MapsListedTwiceCoverEveryEntry)
{
    LevelBand const monastery = MergeBands(DungeonBandFromFinder(18, 59), DungeonBandFromFinder(20, 59));
    EXPECT_EQ(monastery.Low, 18);
    EXPECT_EQ(monastery.High, 59);
}

namespace
{
QuestCurve KoboldCampCleanup()
{
    return QuestScalingTable::CurveFromRecord({ 7, 2, 20, 6, 5, 4, 3, 0, 0, -4, -3, -2, -1, 0, 0 });
}

Player const* AnyPlayer()
{
    static int const placeholder = 0;
    return reinterpret_cast<Player const*>(&placeholder);
}

class ScalingOwnersReset
{
public:
    ~ScalingOwnersReset()
    {
        LocalLevelScaling::ChallengeBlocksOwner.store(nullptr);
        LocalLevelScaling::RulesetBlocksOwner.store(nullptr);
    }
};
}

TEST(LocalLevelScalingTest, QuestScalingRecordKeepsItsBoundsAndPoints)
{
    QuestCurve const curve = KoboldCampCleanup();
    EXPECT_EQ(curve.MinLevel, 2);
    EXPECT_EQ(curve.MaxLevel, 20);
    ASSERT_EQ(curve.Count, 4);
    EXPECT_EQ(curve.Points[0], std::make_pair(6, -4));
    EXPECT_EQ(curve.Points[3], std::make_pair(3, -1));
}

TEST(LocalLevelScalingTest, QuestTrailsTheCharacterWithinItsBounds)
{
    QuestCurve const curve = KoboldCampCleanup();
    EXPECT_EQ(CurveLevel(curve, 2), 2);
    EXPECT_EQ(CurveLevel(curve, 5), 2);
    EXPECT_EQ(CurveLevel(curve, 10), 6);
    EXPECT_EQ(CurveLevel(curve, 32), 20);
}

TEST(LocalLevelScalingTest, QuestIsOnItsCurveOnlyBetweenItsBounds)
{
    QuestCurve const curve = KoboldCampCleanup();
    EXPECT_FALSE(OnCurve(curve, 1));
    EXPECT_TRUE(OnCurve(curve, 10));
    EXPECT_TRUE(OnCurve(curve, 24));
    EXPECT_FALSE(OnCurve(curve, 25));
}

TEST(LocalLevelScalingTest, ScalingNeverLowersAQuest)
{
    QuestCurve const curve = KoboldCampCleanup();
    EXPECT_EQ(EffectiveQuestLevel(2, 32, &curve), 20);
    EXPECT_EQ(EffectiveQuestLevel(2, 32, nullptr), 2);
    EXPECT_EQ(EffectiveQuestLevel(25, 32, &curve), 25);
    EXPECT_EQ(EffectiveQuestLevel(0, 32, nullptr), 32);
}

TEST(LocalLevelScalingTest, PvPRulesetBlocksCreatureAndQuestScaling)
{
    ScalingOwnersReset const reset;
    LocalLevelScaling::ChallengeBlocksOwner.store(
        [](Player const*) -> std::uint8_t { return LocalLevelScaling::ChallengeBlocksCreatureScaling; });
    EXPECT_EQ(LocalLevelScaling::ScalingBlocksFor(AnyPlayer()), LocalLevelScaling::ChallengeBlocksCreatureScaling);

    LocalLevelScaling::RulesetBlocksOwner.store([](Player const*) { return true; });
    EXPECT_EQ(LocalLevelScaling::ScalingBlocksFor(AnyPlayer()),
        LocalLevelScaling::ChallengeBlocksCreatureScaling | LocalLevelScaling::ChallengeBlocksQuestScaling);

    LocalLevelScaling::RulesetBlocksOwner.store([](Player const*) { return false; });
    EXPECT_EQ(LocalLevelScaling::ScalingBlocksFor(AnyPlayer()), LocalLevelScaling::ChallengeBlocksCreatureScaling);
    EXPECT_EQ(LocalLevelScaling::ScalingBlocksFor(nullptr), 0);
}
