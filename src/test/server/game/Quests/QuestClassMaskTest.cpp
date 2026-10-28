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

#include "Field.h"
#include "IntegrationTestFixture.h"
#include "ItemTemplate.h"
#include "QuestDef.h"
#include <array>

namespace
{
constexpr uint32 ClassMask(Classes playerClass)
{
    return uint32(1) << (playerClass - 1);
}

class LoadedClassQuest : public Quest
{
public:
    LoadedClassQuest(::Field* questRecord, uint32 questTemplateAddonClassMask) : Quest(questRecord)
    {
        RequiredClasses = ExpandLegacyQuestClassMask(questTemplateAddonClassMask);
    }
};

class QuestClassMaskTest : public IntegrationTestFixture
{
protected:
    LoadedClassQuest MakeQuest(uint32 questTemplateAddonClassMask)
    {
        std::array<::Field, 106> emptyQuestRecord;
        return LoadedClassQuest(emptyQuestRecord.data(), questTemplateAddonClassMask);
    }

    bool CanTakeQuest(Classes playerClass, Quest const& quest)
    {
        TestPlayer* player = CreateTestPlayer(++_guid);
        player->SetByteValue(UNIT_FIELD_BYTES_0, 1, uint8(playerClass));
        return player->SatisfyQuestClass(&quest, false);
    }

    void ExpectCustomClassesOfStockFamilies(uint32 stockClassMask)
    {
        LoadedClassQuest quest = MakeQuest(stockClassMask);

        for (uint8 classId = CLASS_BARBARIAN; classId < MAX_CLASSES; ++classId)
        {
            bool familyAllowed = (stockClassMask & ClassMask(GetLegacyClassForCustomClass(Classes(classId)))) != 0;
            EXPECT_EQ(CanTakeQuest(Classes(classId), quest), familyAllowed) << stockClassMask << " " << uint32(classId);
        }
    }

private:
    ObjectGuid::LowType _guid = 0;
};
}

TEST_F(QuestClassMaskTest, StockClassQuestsStayClosedToMappedCustomClasses)
{
    struct StockClassQuest
    {
        Classes stockClass;
        Classes mappedCustomClass;
    };

    for (StockClassQuest const& stockQuest : {
             StockClassQuest{CLASS_PALADIN, CLASS_CULTIST},
             StockClassQuest{CLASS_DRUID, CLASS_SON_OF_ARUGAL},
             StockClassQuest{CLASS_DRUID, CLASS_STARCALLER},
             StockClassQuest{CLASS_WARLOCK, CLASS_NECROMANCER},
             StockClassQuest{CLASS_SHAMAN, CLASS_SPIRIT_MAGE},
             StockClassQuest{CLASS_ROGUE, CLASS_MONK}})
    {
        LoadedClassQuest quest = MakeQuest(ClassMask(stockQuest.stockClass));

        EXPECT_TRUE(CanTakeQuest(stockQuest.stockClass, quest)) << uint32(stockQuest.stockClass);
        EXPECT_FALSE(CanTakeQuest(stockQuest.mappedCustomClass, quest)) << uint32(stockQuest.mappedCustomClass);
    }
}

TEST_F(QuestClassMaskTest, GearFamilyQuestsAdmitTheCustomClassesOfTheirFamilies)
{
    ExpectCustomClassesOfStockFamilies(ClassMask(CLASS_PRIEST) | ClassMask(CLASS_MAGE) | ClassMask(CLASS_WARLOCK));
    ExpectCustomClassesOfStockFamilies(
        ClassMask(CLASS_WARRIOR) | ClassMask(CLASS_PALADIN) | ClassMask(CLASS_DEATH_KNIGHT));
    ExpectCustomClassesOfStockFamilies(ClassMask(CLASS_ROGUE) | ClassMask(CLASS_DRUID));
}

TEST_F(QuestClassMaskTest, QuestsForAllButOneStockClassAdmitEveryOtherFamily)
{
    uint32 allStockClasses = CLASSMASK_ALL_PLAYABLE & 0x7FFu;

    ExpectCustomClassesOfStockFamilies(allStockClasses & ~ClassMask(CLASS_DEATH_KNIGHT));
    ExpectCustomClassesOfStockFamilies(allStockClasses & ~ClassMask(CLASS_PRIEST));
    ExpectCustomClassesOfStockFamilies(allStockClasses & ~ClassMask(CLASS_DRUID));

    LoadedClassQuest allButDeathKnight = MakeQuest(allStockClasses & ~ClassMask(CLASS_DEATH_KNIGHT));
    for (uint8 classId = CLASS_BARBARIAN; classId < MAX_CLASSES; ++classId)
        EXPECT_TRUE(CanTakeQuest(Classes(classId), allButDeathKnight)) << uint32(classId);
}

TEST_F(QuestClassMaskTest, AuthoredCustomClassQuestsAdmitOnlyTheirClasses)
{
    LoadedClassQuest cultistQuest = MakeQuest(ClassMask(CLASS_CULTIST));
    EXPECT_TRUE(CanTakeQuest(CLASS_CULTIST, cultistQuest));
    EXPECT_FALSE(CanTakeQuest(CLASS_PALADIN, cultistQuest));

    LoadedClassQuest runemasterQuest = MakeQuest(ClassMask(CLASS_SPIRIT_MAGE));
    EXPECT_TRUE(CanTakeQuest(CLASS_SPIRIT_MAGE, runemasterQuest));
    EXPECT_FALSE(CanTakeQuest(CLASS_SHAMAN, runemasterQuest));

    LoadedClassQuest mixedQuest = MakeQuest(ClassMask(CLASS_NECROMANCER) | ClassMask(CLASS_SHAMAN));
    EXPECT_TRUE(CanTakeQuest(CLASS_NECROMANCER, mixedQuest));
    EXPECT_TRUE(CanTakeQuest(CLASS_SHAMAN, mixedQuest));
    EXPECT_FALSE(CanTakeQuest(CLASS_SPIRIT_MAGE, mixedQuest));
}

TEST_F(QuestClassMaskTest, UnrestrictedQuestsAdmitEveryCustomClass)
{
    LoadedClassQuest quest = MakeQuest(0);

    for (uint8 classId = CLASS_BARBARIAN; classId < MAX_CLASSES; ++classId)
        EXPECT_TRUE(CanTakeQuest(Classes(classId), quest)) << uint32(classId);
}

TEST_F(QuestClassMaskTest, ItemsExpandTheSingleClassMasksQuestsKeep)
{
    uint32 paladinMask = ClassMask(CLASS_PALADIN);

    EXPECT_EQ(GetItemAllowableClassMask(paladinMask), paladinMask | ClassMask(CLASS_CULTIST));
    EXPECT_FALSE(CanTakeQuest(CLASS_CULTIST, MakeQuest(paladinMask)));
}
