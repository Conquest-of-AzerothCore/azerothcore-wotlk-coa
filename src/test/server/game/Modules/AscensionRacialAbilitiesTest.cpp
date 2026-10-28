/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRacialAbilities.h"
#include "gtest/gtest.h"
#include <vector>

namespace
{
SkillLineAbilityEntry RacialAbility(uint32 skillId, uint32 raceMask = 0, uint32 classMask = 0)
{
    SkillLineAbilityEntry ability{};
    ability.SkillLine = skillId;
    ability.RaceMask = raceMask;
    ability.ClassMask = classMask;
    ability.MinSkillLineRank = 1;
    ability.AcquireMethod = SKILL_LINE_ABILITY_LEARNED_ON_SKILL_LEARN;
    return ability;
}
}

TEST(AscensionRacialAbilitiesTest, CoversAllTenRacesAndTwentyOneCustomClasses)
{
    constexpr uint32 racialSkills[] = {754, 125, 101, 126, 220, 124, 753, 733, 756, 760};
    constexpr uint8 races[] = {1, 2, 3, 4, 5, 6, 7, 8, 10, 11};
    for (uint8 index = 0; index < 10; ++index)
    {
        auto ability = RacialAbility(racialSkills[index], uint32(1) << (races[index] - 1), 0xFFFFFA00u);
        EXPECT_EQ(AscensionRacialAbilities::GetRace(racialSkills[index]), races[index]);
        for (uint8 classId = CLASS_BARBARIAN; classId < MAX_CLASSES; ++classId)
            EXPECT_TRUE(AscensionRacialAbilities::CanLearn(ability, races[index], classId));
    }
}

TEST(AscensionRacialAbilitiesTest, RaceComesFromSkillEvenWhenAbilityMaskIsUnrestricted)
{
    // Gemcutting and Blood Elf passives have RaceMask = 0 in the copied DBC.
    auto gemcutting = RacialAbility(SKILL_RACIAL_DRAENEI, 0, 0xFFFFFA00u);
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(gemcutting, RACE_DRAENEI, CLASS_FLESHWARDEN));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(gemcutting, RACE_HUMAN, CLASS_FLESHWARDEN));
    auto magicResistance = RacialAbility(SKILL_RACIAL_BLOODELF, 0, 0xFFFFFA00u);
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(magicResistance, RACE_BLOODELF, CLASS_NECROMANCER));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(magicResistance, RACE_ORC, CLASS_NECROMANCER));
}

TEST(AscensionRacialAbilitiesTest, DraeneiCustomAbilitiesUseTheirAdditionalSkillLine)
{
    auto gift = RacialAbility(11760, 1024, 3909427200u); // Gift of the Naaru 814282.
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(gift, RACE_DRAENEI, CLASS_FLESHWARDEN));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(gift, RACE_DRAENEI, CLASS_GUARDIAN));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(gift, RACE_HUMAN, CLASS_FLESHWARDEN));
}

TEST(AscensionRacialAbilitiesTest, DraeneiSunClericReceivesOnlyTheHybridGift)
{
    auto hybrid = RacialAbility(11760, 1024, 3909427200u);
    hybrid.Spell = AscensionRacialAbilities::SPELL_GIFT_OF_THE_NAARU_HYBRID;
    auto spellPower = RacialAbility(11760, 1024, 48267264u);
    spellPower.Spell = 814280;
    auto attackPower = RacialAbility(11760, 1024, 131072u);
    attackPower.Spell = 814281;
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(hybrid, RACE_DRAENEI, CLASS_SUN_CLERIC));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(spellPower, RACE_DRAENEI, CLASS_SUN_CLERIC));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(attackPower, RACE_DRAENEI, CLASS_SUN_CLERIC));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(hybrid, RACE_HUMAN, CLASS_SUN_CLERIC));
}

TEST(AscensionRacialAbilitiesTest, PreservesAuthoredResourceVariants)
{
    auto manaTorrent = RacialAbility(SKILL_RACIAL_BLOODELF, 512, 2376105984u);
    auto necromancerTorrent = RacialAbility(SKILL_RACIAL_BLOODELF, 512, 4194304);
    auto energyTorrent = RacialAbility(SKILL_RACIAL_BLOODELF, 512, 401408);
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(manaTorrent, RACE_BLOODELF, CLASS_SPIRIT_MAGE));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(manaTorrent, RACE_BLOODELF, CLASS_NECROMANCER));
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(necromancerTorrent, RACE_BLOODELF, CLASS_NECROMANCER));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(energyTorrent, RACE_BLOODELF, CLASS_NECROMANCER));
    auto attackPowerFury = RacialAbility(SKILL_ORC_RACIAL, 2, 1181696);
    auto spellPowerFury = RacialAbility(SKILL_ORC_RACIAL, 2, 12619776);
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(attackPowerFury, RACE_ORC, CLASS_BARBARIAN));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(spellPowerFury, RACE_ORC, CLASS_BARBARIAN));
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(spellPowerFury, RACE_ORC, CLASS_NECROMANCER));
}

TEST(AscensionRacialAbilitiesTest, BloodElfWitchHunterReceivesOnlyTheMultiResourceTorrent)
{
    auto torrent = RacialAbility(SKILL_RACIAL_BLOODELF, 0, 512);
    torrent.Spell = AscensionRacialAbilities::SPELL_ARCANE_TORRENT_ALL_RESOURCES;
    EXPECT_TRUE(AscensionRacialAbilities::CanLearn(torrent, RACE_BLOODELF, CLASS_WITCH_HUNTER));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(torrent, RACE_HUMAN, CLASS_WITCH_HUNTER));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(torrent, RACE_BLOODELF, CLASS_NECROMANCER));
    torrent.Spell = 814287;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(torrent, RACE_BLOODELF, CLASS_WITCH_HUNTER));
    torrent.Spell = AscensionRacialAbilities::SPELL_ARCANE_TORRENT_ALL_RESOURCES;
    torrent.MinSkillLineRank = 2;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(torrent, RACE_BLOODELF, CLASS_WITCH_HUNTER));
    torrent.MinSkillLineRank = 1;
    torrent.SupercededBySpell = 123;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(torrent, RACE_BLOODELF, CLASS_WITCH_HUNTER));
}

TEST(AscensionRacialAbilitiesTest, EveryCustomClassReceivesExactlyOneActiveRacialVariant)
{
    struct Variant
    {
        uint32 SkillId;
        uint32 SpellId;
        uint32 RaceMask;
        uint32 ClassMask;
    };
    constexpr Variant bloodFury[] = {
        {SKILL_ORC_RACIAL, 814283, 2, 1181696u}, {SKILL_ORC_RACIAL, 814284, 2, 12619776u},
        {SKILL_ORC_RACIAL, 814285, 2, 3372294144u}};
    constexpr Variant arcaneTorrent[] = {
        {SKILL_RACIAL_BLOODELF, 28730, 0, 512u}, {SKILL_RACIAL_BLOODELF, 814286, 512, 401408u},
        {SKILL_RACIAL_BLOODELF, 814287, 512, 2376105984u}, {SKILL_RACIAL_BLOODELF, 814288, 512, 536870912u},
        {SKILL_RACIAL_BLOODELF, 814289, 512, 4194304u}, {SKILL_RACIAL_BLOODELF, 814290, 512, 589824u},
        {SKILL_RACIAL_BLOODELF, 814291, 512, 33554432u}, {SKILL_RACIAL_BLOODELF, 814292, 512, 1048576u}};
    constexpr Variant giftOfTheNaaru[] = {
        {11760, 814280, 1024, 48267264u}, {11760, 814281, 1024, 131072u}, {11760, 814282, 1024, 3909427200u}};

    auto learnedVariants = [](auto const& variants, uint8 raceId, uint8 classId)
    {
        std::vector<uint32> learned;
        for (Variant const& variant : variants)
        {
            auto ability = RacialAbility(variant.SkillId, variant.RaceMask, variant.ClassMask);
            ability.Spell = variant.SpellId;
            if (AscensionRacialAbilities::CanLearn(ability, raceId, classId))
                learned.push_back(variant.SpellId);
        }
        return learned;
    };

    for (uint8 classId = CLASS_BARBARIAN; classId < MAX_CLASSES; ++classId)
    {
        EXPECT_EQ(learnedVariants(bloodFury, RACE_ORC, classId).size(), 1u);
        EXPECT_EQ(learnedVariants(arcaneTorrent, RACE_BLOODELF, classId).size(), 1u);
        EXPECT_EQ(learnedVariants(giftOfTheNaaru, RACE_DRAENEI, classId).size(), 1u);
    }

    EXPECT_EQ(learnedVariants(bloodFury, RACE_ORC, CLASS_REAPER), std::vector<uint32>{814285});
    EXPECT_EQ(learnedVariants(arcaneTorrent, RACE_BLOODELF, CLASS_WITCH_DOCTOR), std::vector<uint32>{814287});
    EXPECT_EQ(learnedVariants(arcaneTorrent, RACE_BLOODELF, CLASS_PROPHET), std::vector<uint32>{814287});
    EXPECT_EQ(learnedVariants(giftOfTheNaaru, RACE_DRAENEI, CLASS_RANGER), std::vector<uint32>{814281});
    EXPECT_EQ(learnedVariants(giftOfTheNaaru, RACE_DRAENEI, CLASS_WITCH_DOCTOR), std::vector<uint32>{814280});
    EXPECT_TRUE(learnedVariants(bloodFury, RACE_BLOODELF, CLASS_REAPER).empty());
}

TEST(AscensionRacialAbilitiesTest, RejectsUnrelatedSkillsClassesAndNonDefaultAbilities)
{
    auto ability = RacialAbility(SKILL_RACIAL_HUMAN, 1, 0xFFFFFA00u);
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_HUMAN, CLASS_WARRIOR));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_NONE, CLASS_BARBARIAN));
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_HUMAN, MAX_CLASSES));
    ability.SkillLine = SKILL_SWORDS;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_HUMAN, CLASS_BARBARIAN));
    ability.SkillLine = SKILL_RACIAL_HUMAN;
    ability.AcquireMethod = SKILL_LINE_ABILITY_LEARNED_ON_SKILL_VALUE;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_HUMAN, CLASS_BARBARIAN));
    ability.AcquireMethod = SKILL_LINE_ABILITY_LEARNED_ON_SKILL_LEARN;
    ability.MinSkillLineRank = 2;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_HUMAN, CLASS_BARBARIAN));
    ability.MinSkillLineRank = 1;
    ability.SupercededBySpell = 123;
    EXPECT_FALSE(AscensionRacialAbilities::CanLearn(ability, RACE_HUMAN, CLASS_BARBARIAN));
}
