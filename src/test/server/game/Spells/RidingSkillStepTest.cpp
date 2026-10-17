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

#include "SpellMgr.h"
#include "gtest/gtest.h"

TEST(RidingSkillStepTest, NoviceIsStepOneAndClassicRanksFollow)
{
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 1), RIDING_SKILL_NOVICE);
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 2), RIDING_SKILL_APPRENTICE);
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 3), RIDING_SKILL_JOURNEYMAN);
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 4), RIDING_SKILL_EXPERT);
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 5), RIDING_SKILL_ARTISAN);
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 6), RIDING_SKILL_EXTRAORDINARY);
}

TEST(RidingSkillStepTest, ClassicRidingValuesAreUnchanged)
{
    EXPECT_EQ(RIDING_SKILL_APPRENTICE, 75);
    EXPECT_EQ(RIDING_SKILL_JOURNEYMAN, 150);
    EXPECT_EQ(RIDING_SKILL_EXPERT, 225);
    EXPECT_EQ(RIDING_SKILL_ARTISAN, 300);
}

TEST(RidingSkillStepTest, OtherSkillsKeepSeventyFivePerStep)
{
    EXPECT_EQ(GetSkillValueForStep(SKILL_TAILORING, 1), 75);
    EXPECT_EQ(GetSkillValueForStep(SKILL_TAILORING, 4), 300);
    EXPECT_EQ(GetSkillValueForStep(SKILL_RIDING, 0), 0);
}
