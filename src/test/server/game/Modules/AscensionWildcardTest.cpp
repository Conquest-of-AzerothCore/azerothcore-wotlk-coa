/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWildcard.h"
#include "AscensionWildcardStarterData.h"
#include "gtest/gtest.h"
#include <algorithm>
#include <map>
#include <memory>
#include <random>
#include <set>
#include <span>
#include <string>
#include <unordered_set>

using namespace AscensionWildcard;

namespace
{
using StarterEntry = AscensionWildcardStarterData::Entry;

bool Any(std::uint32_t)
{
    return true;
}

bool Contains(std::span<StarterEntry const> pool, std::uint32_t entryId)
{
    return std::any_of(pool.begin(), pool.end(),
        [entryId](StarterEntry const& entry) { return entry.EntryId == entryId; });
}

RandomBelow Seeded(std::mt19937& rng)
{
    return [&rng](std::uint32_t bound) { return std::uniform_int_distribution<std::uint32_t>(0, bound - 1)(rng); };
}

RandomBelow Fixed(std::uint32_t pick)
{
    return [pick](std::uint32_t bound) { return std::min(pick, bound - 1); };
}

RandomBelow Sequence(std::vector<std::uint32_t> picks)
{
    auto const next = std::make_shared<std::size_t>(0);
    return [picks, next](std::uint32_t bound) { return std::min(picks.at((*next)++), bound - 1); };
}

std::vector<Essence> HeroBudget()
{
    std::vector<Essence> budget;
    for (std::uint32_t level = 1; level <= 80; ++level)
        budget.push_back({ level, level < 10 ? 8 : level - level % 2, level < 11 ? 0 : (level - 9) / 2 });
    return budget;
}

std::vector<Slot> Abilities(std::uint32_t count)
{
    std::vector<Slot> slots;
    for (std::uint32_t entryId = 1; entryId <= count; ++entryId)
        slots.push_back({ entryId });
    return slots;
}

Slot TalentSlot(std::uint32_t entryId)
{
    return { entryId, false, 1, true };
}

Entry Ability(std::uint32_t entryId, std::uint32_t minLevel, std::uint32_t group = 0)
{
    return { entryId, false, minLevel, group, { entryId * 10 } };
}

Entry Talent(std::uint32_t entryId, std::uint32_t minLevel, std::uint32_t ranks)
{
    Entry entry{ entryId, true, minLevel, 0, {} };
    for (std::uint32_t rank = 1; rank <= ranks; ++rank)
        entry.RankSpells.push_back(entryId * 10 + rank);
    return entry;
}

std::vector<AscensionCoATalentState::KnownEntry> Upload(std::vector<Slot> const& slots,
    std::vector<std::uint32_t> const& paths)
{
    std::vector<AscensionCoATalentState::KnownEntry> upload;
    for (Slot const& slot : slots)
        if (slot.EntryId)
            upload.push_back({ slot.EntryId, slot.Rank });
    for (std::uint32_t path : paths)
        upload.push_back({ path, 1 });
    return upload;
}

std::vector<Slot> Leveled()
{
    std::vector<Slot> slots = Abilities(4);
    slots.push_back({ 201, false, 3, true });
    return slots;
}

struct KnownEntryRecord
{
    std::uint32_t EntryId;
    std::uint32_t Rank;
    std::uint32_t LearnedSpellRank;
    std::uint8_t Locked;
    std::uint32_t LearnOrder;
    std::uint32_t Reserved;
};

std::uint32_t ReadUInt32(std::vector<std::uint8_t> const& data, std::size_t offset)
{
    return std::uint32_t(data[offset]) | (std::uint32_t(data[offset + 1]) << 8) |
        (std::uint32_t(data[offset + 2]) << 16) | (std::uint32_t(data[offset + 3]) << 24);
}

KnownEntryRecord ReadRecord(std::vector<std::uint8_t> const& payload, std::size_t index)
{
    std::size_t const offset = sizeof(std::uint32_t) + index * 21;
    return { ReadUInt32(payload, offset), ReadUInt32(payload, offset + 4), ReadUInt32(payload, offset + 8),
        payload[offset + 12], ReadUInt32(payload, offset + 13), ReadUInt32(payload, offset + 17) };
}

void ExpectDistinctStarters(std::vector<Slot> const& slots)
{
    ASSERT_EQ(slots.size(), STARTING_ABILITY_COUNT);
    EXPECT_TRUE(Contains(AscensionWildcardStarterData::FirstAbility, slots[0].EntryId));
    std::set<std::uint32_t> distinct;
    for (Slot const& slot : slots)
    {
        EXPECT_TRUE(Contains(AscensionWildcardStarterData::OtherAbilities, slot.EntryId));
        distinct.insert(slot.EntryId);
    }
    EXPECT_EQ(distinct.size(), STARTING_ABILITY_COUNT);
}
}

TEST(AscensionWildcardTest, FirstRollGivesACoreAttackAndThreeOtherDistinctStarters)
{
    std::mt19937 rng(7);
    for (int roll = 0; roll < 500; ++roll)
    {
        std::vector<Slot> const slots = RollStartingAbilities({}, Seeded(rng), Any);
        ExpectDistinctStarters(slots);
        EXPECT_TRUE(std::none_of(slots.begin(), slots.end(), [](Slot const& slot) { return slot.Locked; }));
    }
}

TEST(AscensionWildcardTest, RerollKeepsLockedSlotsInPlace)
{
    std::mt19937 rng(11);
    std::vector<Slot> slots = RollStartingAbilities({}, Seeded(rng), Any);
    slots[0].Locked = true;
    slots[2].Locked = true;
    for (int roll = 0; roll < 500; ++roll)
    {
        std::vector<Slot> const next = RollStartingAbilities(slots, Seeded(rng), Any);
        ExpectDistinctStarters(next);
        EXPECT_EQ(next[0].EntryId, slots[0].EntryId);
        EXPECT_EQ(next[2].EntryId, slots[2].EntryId);
        EXPECT_TRUE(next[0].Locked && next[2].Locked);
        EXPECT_FALSE(next[1].Locked || next[3].Locked);
    }
}

TEST(AscensionWildcardTest, RerolledSlotsMayDrawWhatTheyHeldBefore)
{
    std::uint32_t const pick = 0;
    std::vector<Slot> const first = RollStartingAbilities({}, Fixed(pick), Any);
    EXPECT_EQ(RollStartingAbilities(first, Fixed(pick), Any)[0].EntryId, first[0].EntryId);
}

TEST(AscensionWildcardTest, PicksFollowTheHarvestedWeights)
{
    auto const& pool = AscensionWildcardStarterData::FirstAbility;
    std::uint32_t pick = pool[0].Weight - 1;
    EXPECT_EQ(RollStartingAbilities({}, Fixed(pick), Any)[0].EntryId, pool[0].EntryId);
    pick = pool[0].Weight;
    EXPECT_EQ(RollStartingAbilities({}, Fixed(pick), Any)[0].EntryId, pool[1].EntryId);
    pick = UINT32_MAX;
    EXPECT_EQ(RollStartingAbilities({}, Fixed(pick), Any)[0].EntryId, pool.back().EntryId);
}

TEST(AscensionWildcardTest, SpellsTheCharacterCannotTakeAreNeverRolled)
{
    auto const& pool = AscensionWildcardStarterData::FirstAbility;
    std::set<std::uint32_t> blocked;
    for (StarterEntry const& entry : pool)
        if (entry.EntryId != pool[5].EntryId)
            blocked.insert(entry.SpellId);

    std::mt19937 rng(3);
    SpellFilter const available = [&blocked](std::uint32_t spellId) { return !blocked.count(spellId); };
    for (int roll = 0; roll < 100; ++roll)
    {
        std::vector<Slot> const slots = RollStartingAbilities({}, Seeded(rng), available);
        EXPECT_EQ(slots[0].EntryId, pool[5].EntryId);
        for (Slot const& slot : slots)
            EXPECT_FALSE(blocked.count(SpellOf(slot.EntryId)));
    }
}

TEST(AscensionWildcardTest, EssenceOpensAbilityRollsOnEvenAndTalentRollsOnOddLevels)
{
    std::vector<Essence> const budget = HeroBudget();
    std::vector<Slot> const starters = Abilities(4);
    EXPECT_FALSE(PoolLevel(budget, starters, 9, false));
    EXPECT_EQ(PoolLevel(budget, starters, 10, false), 10u);
    EXPECT_FALSE(PoolLevel(budget, starters, 10, true));
    EXPECT_EQ(PoolLevel(budget, starters, 11, true), 11u);
    EXPECT_EQ(PoolLevel(budget, starters, 20, false), 11u);
    EXPECT_EQ(PoolLevel(budget, starters, 20, true), 12u);

    std::vector<Slot> leveled = Abilities(5);
    leveled.push_back(TalentSlot(201));
    EXPECT_FALSE(PoolLevel(budget, leveled, 11, false));
    EXPECT_EQ(PoolLevel(budget, leveled, 12, false), 12u);
    EXPECT_FALSE(PoolLevel(budget, leveled, 12, true));
    EXPECT_EQ(PoolLevel(budget, leveled, 13, true), 13u);
}

TEST(AscensionWildcardTest, LevelRollsCatchUpInTheOrderTheyWereEarned)
{
    Tables const tables{ { Ability(101, 1), Ability(102, 1), Ability(103, 1), Talent(201, 10, 1), Talent(202, 10, 1) },
        HeroBudget() };
    std::vector<Slot> slots = Abilities(4);
    std::vector<bool> talents;
    while (std::optional<Slot> const rolled = RollLevelEntry(tables, slots, 13, 0, Fixed(0), Any))
    {
        talents.push_back(rolled->Talent);
        Place(slots, *rolled);
    }
    EXPECT_EQ(talents, (std::vector<bool>{ false, true, false, true }));
}

TEST(AscensionWildcardTest, LevelRollsDrawFromEntriesUpToTheirPoolLevel)
{
    Tables const tables{ { Ability(101, 10), Ability(102, 12), Ability(103, 20) }, HeroBudget() };
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Fixed(0), Any)->EntryId, 101u);
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Fixed(UINT32_MAX), Any)->EntryId, 102u);
    EXPECT_EQ(RollLevelEntry(tables, Abilities(4), 20, 0, Fixed(UINT32_MAX), Any)->EntryId, 101u);
    EXPECT_FALSE(RollLevelEntry(tables, Abilities(4), 9, 0, Fixed(0), Any));
}

TEST(AscensionWildcardTest, SynergyComesFromSpellModifiersSpecializationsAndSchools)
{
    Tables tables;
    tables.Linked[10] = { 20 };
    tables.Linked[20] = { 10 };
    tables.SynergyTags[10] = { 88, 18 };
    tables.SynergyTags[20] = { 88 };
    tables.SynergyTags[30] = { 104, 18 };
    tables.SynergyTags[40] = { 19 };
    EXPECT_EQ(SynergyTagWeight(88), 2u);
    EXPECT_EQ(SynergyTagWeight(18), 1u);
    EXPECT_EQ(SynergyTagWeight(8), 0u);
    EXPECT_EQ(SynergyScore(tables, 20, { 10 }), SynergySettings{}.LinkWeight + 2);
    EXPECT_EQ(SynergyScore(tables, 30, { 10 }), 1u);
    EXPECT_EQ(SynergyScore(tables, 40, { 10 }), 0u);
    EXPECT_EQ(SynergyScore(tables, 30, { 10, 20 }), 1u);
    EXPECT_EQ(SynergyScore(tables, 20, {}), 0u);
}

TEST(AscensionWildcardTest, TalentsRelateToOtherClassesAbilitiesOfTheSchoolAndEffectTheyModify)
{
    std::uint32_t const fire = 18;
    std::uint32_t const frost = 19;
    std::uint32_t const directDamage = 134;
    std::uint32_t const damageOverTime = 5;
    Tables tables{ { Talent(1, 10, 1), Ability(10, 1), Ability(20, 1), Ability(30, 1), Ability(40, 1),
        Ability(50, 1) }, HeroBudget() };
    tables.SpellTags[100] = { fire, directDamage };
    tables.SpellTags[200] = { fire, directDamage, 8 };
    tables.SpellTags[300] = { frost, directDamage };
    tables.SpellTags[400] = { fire, damageOverTime };
    tables.SpellTags[500] = { fire, directDamage };
    tables.Linked[1] = { 10 };
    tables.Linked[10] = { 1 };
    RelateAcrossClasses(tables, { 50 });
    EXPECT_EQ(tables.Related[1], (std::unordered_set<std::uint32_t>{ 20 }));
    EXPECT_FALSE(tables.Related.contains(50));
    EXPECT_EQ(tables.Related[20], (std::unordered_set<std::uint32_t>{ 1 }));
    EXPECT_FALSE(tables.Related.contains(10));
    EXPECT_EQ(SynergyScore(tables, 20, { 1 }), SynergySettings{}.RelatedWeight);
    EXPECT_EQ(SynergyScore(tables, 1, { 10, 20, 30 }), SynergySettings{}.LinkWeight + SynergySettings{}.RelatedWeight);
}

TEST(AscensionWildcardTest, ASynergyRollFavoursEntriesThatFitTheBuild)
{
    Tables tables{ { Ability(101, 1), Ability(102, 1), Ability(103, 1) }, HeroBudget() };
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Fixed(0), Any)->EntryId, 101u);

    tables.Linked[103] = { 1 };
    tables.Linked[1] = { 103 };
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Sequence({ 0, 0 }), Any)->EntryId, 103u);
    std::uint32_t const chance = SynergySettings{}.ChancePercent;
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Sequence({ chance - 1, 2 }), Any)->EntryId, 103u);
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Sequence({ chance, 0 }), Any)->EntryId, 101u);
    EXPECT_EQ(RollLevelEntry(tables, Abilities(4), 20, 0, Sequence({ 0, 0 }), Any)->EntryId, 103u);

    SynergySettings never;
    never.ChancePercent = 0;
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Sequence({ 0, 0 }), Any, {}, never)->EntryId, 101u);
}

TEST(AscensionWildcardTest, SynergyReasonsAddUpToTheScore)
{
    Tables tables;
    tables.Linked[10] = { 20 };
    tables.Linked[20] = { 10 };
    tables.Mentioned[20] = { 30 };
    tables.SynergyTags[10] = { 88, 18 };
    tables.SynergyTags[20] = { 88, 18 };
    tables.SynergyTags[30] = { 17 };
    std::vector<SynergyReason> const reasons = SynergyReasons(tables, 20, { 10, 30, 40 });
    ASSERT_EQ(reasons.size(), 4u);
    EXPECT_EQ(reasons[0].Known, 10u);
    EXPECT_EQ(reasons[0].Kind, SynergyKind::Link);
    EXPECT_EQ(reasons[1].Kind, SynergyKind::Tag);
    EXPECT_EQ(reasons[1].Tag, 88u);
    EXPECT_EQ(reasons[1].Points, 2u);
    EXPECT_EQ(reasons[2].Tag, 18u);
    EXPECT_EQ(reasons[3].Known, 30u);
    EXPECT_EQ(reasons[3].Kind, SynergyKind::Tooltip);
    std::uint32_t points = 0;
    for (SynergyReason const& reason : reasons)
        points += reason.Points;
    EXPECT_EQ(points, SynergyScore(tables, 20, { 10, 30, 40 }));

    SynergySettings noSchools;
    noSchools.SchoolTagWeight = 0;
    EXPECT_EQ(SynergyReasons(tables, 20, { 10 }, noSchools).size(), 2u);
}

TEST(AscensionWildcardTest, RollTracesTellHowTheEntryWasPicked)
{
    Tables tables{ { Ability(101, 1), Ability(102, 1), Ability(103, 1) }, HeroBudget() };
    tables.Linked[103] = { 1 };
    tables.Linked[1] = { 103 };
    std::uint32_t const chance = SynergySettings{}.ChancePercent;

    RollTrace synergy;
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Sequence({ 0, 0 }), Any, {}, {}, &synergy)->EntryId, 103u);
    EXPECT_EQ(synergy.Source, RollSource::Synergy);
    EXPECT_EQ(synergy.Score, 3u);
    EXPECT_EQ(synergy.Total, 3u);
    EXPECT_EQ(synergy.Candidates, 3u);
    EXPECT_EQ(synergy.Scored, 1u);

    RollTrace random;
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Sequence({ chance, 0 }), Any, {}, {}, &random)->EntryId,
        101u);
    EXPECT_EQ(random.Source, RollSource::Random);
    EXPECT_EQ(random.Score, 0u);
    EXPECT_EQ(random.Total, 3u);

    RollTrace card;
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 12, 0, Fixed(0), Any, { Slot{ 102 } }, {}, &card)->EntryId,
        102u);
    EXPECT_EQ(card.Source, RollSource::Card);
}

TEST(AscensionWildcardTest, SynergyWeightsComeFromTheSettings)
{
    Tables tables;
    tables.Linked[10] = { 20 };
    tables.Linked[20] = { 10 };
    tables.SynergyTags[10] = { 88, 18 };
    tables.SynergyTags[20] = { 88, 18 };
    SynergySettings synergy;
    synergy.LinkWeight = 10;
    synergy.SpecTagWeight = 5;
    synergy.SchoolTagWeight = 0;
    EXPECT_EQ(SynergyScore(tables, 20, { 10 }, synergy), 15u);
    EXPECT_EQ(SynergyScore(tables, 20, { 10 }), 6u);
}

TEST(AscensionWildcardTest, TalentsScoreTheAbilitiesTheirTooltipsName)
{
    Tables tables;
    tables.Mentioned[1] = { 10 };
    tables.Mentioned[10] = { 1 };
    EXPECT_EQ(SynergyScore(tables, 10, { 1 }), SynergySettings{}.TooltipWeight);
    EXPECT_EQ(SynergyScore(tables, 1, { 10, 20 }), SynergySettings{}.TooltipWeight);
    EXPECT_EQ(SynergyScore(tables, 20, { 1 }), 0u);

    SynergySettings synergy;
    synergy.TooltipWeight = 7;
    EXPECT_EQ(SynergyScore(tables, 10, { 1 }, synergy), 7u);
}

TEST(AscensionWildcardTest, OnlyARealmThatPlaysWildcardHoldsTheSeasonContent)
{
    EXPECT_TRUE(PlaysWildcard("WildCard"));
    EXPECT_TRUE(PlaysWildcard("Resolute, WildCard "));
    EXPECT_FALSE(PlaysWildcard(""));
    EXPECT_FALSE(PlaysWildcard("Resolute,Felforged"));
}

TEST(AscensionWildcardTest, WeaponAttacksKeepTheirSchoolsApartFromSpells)
{
    std::uint32_t const fire = 18;
    std::uint32_t const mageFire = 88;
    EXPECT_EQ(SynergyTagOf(fire, false), fire);
    EXPECT_EQ(SynergyTagOf(fire, true), fire + WEAPON_SCHOOL_TAG_OFFSET);
    EXPECT_EQ(SynergyTagOf(mageFire, true), mageFire);
    EXPECT_EQ(SynergyTagWeight(fire + WEAPON_SCHOOL_TAG_OFFSET), SynergySettings{}.SchoolTagWeight);
    EXPECT_EQ(SynergyTagWeight(mageFire + WEAPON_SCHOOL_TAG_OFFSET), 0u);

    Tables tables;
    tables.SynergyTags[1] = { fire };
    tables.SynergyTags[2] = { SynergyTagOf(fire, true) };
    tables.SynergyTags[3] = { SynergyTagOf(fire, true) };
    EXPECT_EQ(SynergyScore(tables, 2, { 1 }), 0u);
    EXPECT_EQ(SynergyScore(tables, 2, { 3 }), SynergySettings{}.SchoolTagWeight);
}

TEST(AscensionWildcardTest, TalentsForAbilitiesTheBuildLacksAreNotRolled)
{
    Tables tables{ { Talent(201, 10, 1), Talent(202, 10, 1), Talent(203, 10, 1), Talent(204, 10, 1) }, HeroBudget() };
    tables.Linked[201] = { 50 };
    tables.Linked[50] = { 201 };
    tables.Linked[203] = { 1 };
    tables.Linked[1] = { 203 };
    tables.Mentioned[204] = { 60 };
    tables.Mentioned[60] = { 204 };

    auto const rolled = [&tables](SynergySettings const& synergy)
    {
        std::mt19937 rng(9);
        std::set<std::uint32_t> entries;
        for (int roll = 0; roll < 300; ++roll)
            entries.insert(RollLevelEntry(tables, Abilities(5), 11, 0, Seeded(rng), Any, {}, synergy)->EntryId);
        return entries;
    };
    EXPECT_EQ(rolled({}), (std::set<std::uint32_t>{ 202, 203 }));

    SynergySettings anyTalent;
    anyTalent.TalentsNeedTarget = false;
    EXPECT_EQ(rolled(anyTalent), (std::set<std::uint32_t>{ 201, 202, 203, 204 }));

    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 11, 0, Fixed(0), Any, { TalentSlot(201) })->EntryId, 201u);
}

TEST(AscensionWildcardTest, GlyphsAreNeverRolled)
{
    Tables tables{ { Talent(201, 10, 1), Talent(202, 10, 1) }, HeroBudget() };
    tables.Entries[1].Glyph = true;
    std::mt19937 rng(5);
    for (int roll = 0; roll < 100; ++roll)
        EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 11, 0, Seeded(rng), Any)->EntryId, 201u);
    EXPECT_EQ(RollLevelEntry(tables, Abilities(5), 11, 0, Fixed(0), Any, { TalentSlot(202) })->EntryId, 201u);
}

TEST(AscensionWildcardTest, TalentRollsGrantARandomRankUpToTheMaximum)
{
    Tables const tables{ { Talent(201, 10, 5) }, HeroBudget() };
    for (std::uint32_t pick : { 0u, 2u, 4u, UINT32_MAX })
    {
        std::optional<Slot> const rolled = RollLevelEntry(tables, Abilities(5), 11, 0, Fixed(pick), Any);
        ASSERT_TRUE(rolled);
        EXPECT_TRUE(rolled->Talent);
        EXPECT_EQ(rolled->Rank, std::min(pick, 4u) + 1);
    }

    std::mt19937 rng(5);
    std::set<std::uint32_t> ranks;
    for (int roll = 0; roll < 200; ++roll)
        ranks.insert(RollLevelEntry(tables, Abilities(5), 11, 0, Seeded(rng), Any)->Rank);
    EXPECT_EQ(ranks, (std::set<std::uint32_t>{ 1, 2, 3, 4, 5 }));
}

TEST(AscensionWildcardTest, KnownAndLastUnlearnedEntriesAreNotRolled)
{
    Tables const tables{ { Ability(101, 1), Ability(102, 1) }, HeroBudget() };
    std::vector<Slot> slots = Abilities(4);
    slots[3] = { 101 };
    EXPECT_EQ(RollLevelEntry(tables, slots, 10, 0, Fixed(0), Any)->EntryId, 102u);
    EXPECT_FALSE(RollLevelEntry(tables, slots, 10, 102, Fixed(0), Any));
}

TEST(AscensionWildcardTest, OnlyOneTameSpellIsEverRolled)
{
    Tables const tables{ { Ability(101, 1, TAME_GROUP), Ability(102, 1, TAME_GROUP), Ability(103, 1) },
        HeroBudget() };
    std::vector<Slot> slots = Abilities(3);
    slots.push_back({ 101 });
    EXPECT_EQ(RollLevelEntry(tables, slots, 10, 0, Fixed(0), Any)->EntryId, 103u);
}

TEST(AscensionWildcardTest, LevelRollsSkipSpellsTheCharacterCannotTake)
{
    Tables const tables{ { Ability(101, 1), Ability(102, 1) }, HeroBudget() };
    SpellFilter const available = [](std::uint32_t spellId) { return spellId != 1010; };
    EXPECT_EQ(RollLevelEntry(tables, Abilities(4), 10, 0, Fixed(0), available)->EntryId, 102u);
}

TEST(AscensionWildcardTest, RolledEntriesFillTheFirstFreeSlot)
{
    std::vector<Slot> slots = { { 1 }, {}, { 3 } };
    Place(slots, { 7 });
    EXPECT_EQ(slots[1].EntryId, 7u);
    Place(slots, { 8 });
    ASSERT_EQ(slots.size(), 4u);
    EXPECT_EQ(slots[3].EntryId, 8u);
}

TEST(AscensionWildcardTest, UnlearnNeedsAKnownUnlockedEntryAndNoPendingRollOfItsKind)
{
    std::vector<Essence> const budget = HeroBudget();
    std::vector<Slot> slots = Abilities(5);
    slots[1].Locked = true;
    slots.push_back(TalentSlot(201));
    EXPECT_STREQ(CheckUnlearn(budget, slots, 12, 999), "CA_UNLEARN_NOT_KNOWN");
    EXPECT_STREQ(CheckUnlearn(budget, slots, 12, 0), "CA_UNLEARN_NOT_KNOWN");
    EXPECT_STREQ(CheckUnlearn(budget, slots, 11, 2), "CA_UNLEARN_LOCKED");
    EXPECT_STREQ(CheckUnlearn(budget, slots, 11, 1), "CA_UNLEARN_OK");
    EXPECT_STREQ(CheckUnlearn(budget, slots, 12, 1), "CA_UNLEARN_WILDCARD_UNSPENT_AE");
    EXPECT_STREQ(CheckUnlearn(budget, slots, 12, 201), "CA_UNLEARN_OK");
    EXPECT_STREQ(CheckUnlearn(budget, slots, 13, 201), "CA_UNLEARN_WILDCARD_UNSPENT_TE");
    EXPECT_STREQ(CheckUnlearn(budget, Abilities(4), 10, 1), "CA_UNLEARN_OK");
}

TEST(AscensionWildcardTest, ScrollsOfTheEntryKindAreSpentBeforeGenericOnes)
{
    EXPECT_EQ(ScrollToSpend({ 1, 1, 0 }, false), SCROLL_ABILITIES);
    EXPECT_EQ(ScrollToSpend({ 1, 1, 0 }, true), SCROLL_GENERIC);
    EXPECT_EQ(ScrollToSpend({ 2, 0, 1 }, true), SCROLL_TALENTS);
    EXPECT_FALSE(ScrollToSpend({ 0, 0, 0 }, false));
}

TEST(AscensionWildcardTest, RapidRollsSpendAScrollPerRerollUntilADesiredEntryIsLearned)
{
    Tables const tables{ { Ability(101, 1), Ability(102, 1), Ability(103, 1), Ability(104, 1) }, HeroBudget() };
    RapidRoll const rapid = RollRapidly(tables, Abilities(4), 10, 0, { 5, { 103 }, {} }, { 0, 5, 0 }, Fixed(0), Any);
    ASSERT_TRUE(rapid.Rolled);
    EXPECT_EQ(rapid.Rolled->EntryId, 103u);
    EXPECT_STREQ(rapid.StopCode, "STOP_RAPID_ROLLING_DESIRED_ENTRY_LEARNED");
    EXPECT_EQ(rapid.Spent, (std::vector<Scroll>{ SCROLL_ABILITIES, SCROLL_ABILITIES }));
    EXPECT_EQ(rapid.LastSkipped, 102u);
}

TEST(AscensionWildcardTest, RapidRollsStopOnAnEntryWithADesiredSpellTag)
{
    Tables tables{ { Ability(101, 1), Ability(102, 1), Ability(103, 1) }, HeroBudget() };
    tables.SpellTags[1020] = { 23 };
    RapidRoll const rapid = RollRapidly(tables, Abilities(4), 10, 0, { 5, {}, { 23 } }, { 0, 5, 0 }, Fixed(0), Any);
    ASSERT_TRUE(rapid.Rolled);
    EXPECT_EQ(rapid.Rolled->EntryId, 102u);
    EXPECT_STREQ(rapid.StopCode, "STOP_RAPID_ROLLING_DESIRED_ENTRY_LEARNED");
    EXPECT_EQ(rapid.Spent.size(), 1u);
}

TEST(AscensionWildcardTest, RapidRollsKeepTheLastRollWhenTheCountScrollsOrPoolRunOut)
{
    Tables const tables{ { Ability(101, 1), Ability(102, 1), Ability(103, 1), Ability(104, 1) }, HeroBudget() };
    RapidRequest const request{ 3, { 999 }, {} };
    RapidRoll const counted = RollRapidly(tables, Abilities(4), 10, 0, request, { 0, 5, 0 }, Fixed(0), Any);
    EXPECT_EQ(counted.Rolled->EntryId, 103u);
    EXPECT_STREQ(counted.StopCode, "STOP_RAPID_ROLLING_COUNT_DEPLETED");
    EXPECT_EQ(counted.Spent.size(), 2u);

    RapidRoll const broke = RollRapidly(tables, Abilities(4), 10, 0, request, { 1, 0, 0 }, Fixed(0), Any);
    EXPECT_EQ(broke.Rolled->EntryId, 102u);
    EXPECT_EQ(broke.Spent, (std::vector<Scroll>{ SCROLL_GENERIC }));

    RapidRoll const drained = RollRapidly(tables, Abilities(4), 10, 101, { 5, { 999 }, {} }, { 0, 5, 0 }, Fixed(0),
        [](std::uint32_t spellId) { return spellId != 1040; });
    EXPECT_EQ(drained.Rolled->EntryId, 103u);
    EXPECT_EQ(drained.Spent.size(), 1u);
    EXPECT_EQ(drained.LastSkipped, 102u);
}

TEST(AscensionWildcardTest, LongerRapidRollsUnlockWithTheRerollsOfTheirKind)
{
    EXPECT_EQ(RapidRollLimit(0, true), 5u);
    EXPECT_EQ(RapidRollLimit(49, true), 5u);
    EXPECT_EQ(RapidRollLimit(50, true), 10u);
    EXPECT_EQ(RapidRollLimit(49, false), 5u);
    EXPECT_EQ(RapidRollLimit(5000, false), 10u);
}

TEST(AscensionWildcardTest, EachSpecializationRedeemsAndRollsItsOwnScrolls)
{
    EXPECT_EQ(ScrollTokenName({ 0, SCROLL_GENERIC }), "TOKEN_TYPE_SCROLL_OF_FORTUNE_I");
    EXPECT_EQ(ScrollTokenName({ 1, SCROLL_ABILITIES }), "TOKEN_TYPE_SCROLL_OF_FORTUNE_II_ABILITIES");
    EXPECT_EQ(ScrollTokenName({ 19, SCROLL_TALENTS }), "TOKEN_TYPE_SCROLL_OF_FORTUNE_XX_TALENTS");
    std::optional<ScrollToken> const secondAbilities = ScrollTokenOf(21);
    ASSERT_TRUE(secondAbilities);
    EXPECT_EQ(secondAbilities->Spec, 1u);
    EXPECT_EQ(secondAbilities->Kind, SCROLL_ABILITIES);
    EXPECT_EQ(ScrollTokenOf(59)->Kind, SCROLL_TALENTS);
    EXPECT_FALSE(ScrollTokenOf(60));
    EXPECT_FALSE(ScrollTokenOf(-1));

    EXPECT_EQ(SpecSettingSource("core.wildcard", 0), "core.wildcard");
    EXPECT_EQ(SpecSettingSource("core.wildcard.scrolls", 1), "core.wildcard.scrolls.spec2");
    EXPECT_LE(SpecSettingSource("core.wildcard.startercards", 19).size(), 40u);
}

TEST(AscensionWildcardTest, AStatPathIsChosenOrSwitchedThroughTheBuild)
{
    std::vector<Slot> const slots = Leveled();
    BuildChoice const chosen = CheckBuildUpload(slots, 0, Upload(slots, { 1150 }));
    EXPECT_STREQ(chosen.Result, "CA_UPDATE_ENTRIES_OK");
    EXPECT_EQ(chosen.PrimaryStat, 1150u);

    BuildChoice const switched = CheckBuildUpload(slots, 1150, Upload(slots, { 1150, 1151 }));
    EXPECT_STREQ(switched.Result, "CA_UPDATE_ENTRIES_OK");
    EXPECT_EQ(switched.PrimaryStat, 1151u);

    EXPECT_EQ(CheckBuildUpload(slots, 1150, Upload(slots, {})).PrimaryStat, 1150u);
    EXPECT_EQ(CheckBuildUpload(slots, 1150, Upload(slots, { 1150 })).PrimaryStat, 1150u);
}

TEST(AscensionWildcardTest, TheBuildCannotLearnOrDropRolledEntries)
{
    std::vector<Slot> const slots = Leveled();
    BuildChoice const learned = CheckBuildUpload(slots, 1150, Upload(slots, { 40069 }));
    EXPECT_STREQ(learned.Result, "CA_UPDATE_ENTRIES_BAD_ENTRY");
    EXPECT_STREQ(learned.Learn, "CA_LEARN_NOT_WILDCARD");
    EXPECT_EQ(learned.PrimaryStat, 1150u);

    std::vector<Slot> fewer = slots;
    fewer.pop_back();
    EXPECT_STREQ(CheckBuildUpload(slots, 1150, Upload(fewer, { 1151 })).Result, "CA_UPDATE_ENTRIES_BAD_ENTRY");

    std::vector<Slot> ranked = slots;
    ranked.back().Rank = 5;
    EXPECT_STREQ(CheckBuildUpload(slots, 0, Upload(ranked, {})).Result, "CA_UPDATE_ENTRIES_BAD_ENTRY");

    EXPECT_STREQ(CheckBuildUpload(slots, 0, Upload(slots, { 1150, 1151 })).Result, "CA_UPDATE_ENTRIES_BAD_ENTRY");
}

TEST(AscensionWildcardTest, TheStatPathTravelsWithTheKnownEntries)
{
    std::vector<AscensionCoATalentState::KnownEntry> const known = KnownEntries(Abilities(2), 1152);
    ASSERT_EQ(known.size(), 3u);
    EXPECT_EQ(known.back().EntryId, 1152u);
    EXPECT_EQ(known.back().Rank, 1u);
    EXPECT_EQ(known.back().LearnOrder, 0u);
    EXPECT_EQ(KnownEntries(Abilities(2)).size(), 2u);
}

TEST(AscensionWildcardTest, SilasHandsOutEachLevelingMilestoneOnce)
{
    std::uint32_t const tier = 0;
    char const* const tooLow = "COLLECT_SCROLL_OF_FORTUNE_REWARDS_TOO_LOW_LEVEL";
    char const* const invalid = "COLLECT_SCROLL_OF_FORTUNE_REWARDS_INVALID_COUNT";
    EXPECT_STREQ(CheckScrollClaim(tier, 1, true, 0, 9, 60, 0), tooLow);
    EXPECT_STREQ(CheckScrollClaim(tier, 1, true, 0, 10, 60, 0), CLAIM_OK);
    EXPECT_STREQ(CheckScrollClaim(tier, 1, true, 1, 19, 60, 0), tooLow);
    EXPECT_STREQ(CheckScrollClaim(tier, 2, true, 1, 30, 60, 0), CLAIM_OK);
    EXPECT_STREQ(CheckScrollClaim(tier, 5, true, 1, 60, 60, 0), CLAIM_OK);
    EXPECT_STREQ(CheckScrollClaim(tier, 1, true, 6, 60, 60, 0), invalid);
    EXPECT_STREQ(CheckScrollClaim(tier, 0, true, 0, 60, 60, 0), invalid);
    EXPECT_STREQ(CheckScrollClaim(1, 1, true, 0, 60, 60, 0), CLAIM_OK);
    EXPECT_STREQ(CheckScrollClaim(SPECIALIZATION_COUNT, 1, true, 0, 60, 60, 0),
        "COLLECT_SCROLL_OF_FORTUNE_REWARDS_SPECIALIZATION_OUT_OF_RANGE");
    EXPECT_STREQ(CheckScrollClaim(tier, 101, true, 0, 60, 60, 0), "COLLECT_SCROLL_OF_FORTUNE_REWARDS_COUNT_TOO_HIGH");
}

TEST(AscensionWildcardTest, SilasSellsEndgameScrollsForTheObservedRunePrices)
{
    EXPECT_EQ(EndgameScrollClaimCost(1), 250u);
    EXPECT_EQ(EndgameScrollClaimCost(8), 320u);
    EXPECT_EQ(EndgameScrollClaimCost(21), 450u);
    EXPECT_EQ(EndgameScrollClaimCost(22), 450u);
    EXPECT_EQ(EndgameScrollClaimCost(55), 2100u);
    EXPECT_EQ(EndgameScrollClaimsCost(0, 7), 1960u);
    EXPECT_EQ(EndgameScrollClaimsCost(0, 11), 3300u);
    EXPECT_EQ(EndgameScrollClaimsCost(0, 31), 14100u);
    EXPECT_EQ(EndgameScrollClaimsCost(0, 41), 25850u);
    EXPECT_EQ(EndgameScrollClaimsCost(0, 78), 112800u);
    EXPECT_EQ(EndgameScrollClaimsCost(0, 81), 122850u);
    EXPECT_EQ(EndgameScrollClaimsCost(7, 1), 320u);

    std::array<std::pair<std::uint32_t, std::uint32_t>, 4> const rewards = EndgameScrollClaimRewards(1);
    EXPECT_EQ(rewards[0], std::make_pair(SCROLL_OF_FORTUNE_ITEMS[1], 1u));
    EXPECT_EQ(rewards[1], std::make_pair(TALENT_SCROLL_OF_FORTUNE_ITEM + 1, 2u));
    EXPECT_EQ(rewards[2], std::make_pair(CARD_PACKS[0].Item, 1u));
    EXPECT_EQ(rewards[3], std::make_pair(CARD_PACKS[2].Item, 1u));

    EXPECT_STREQ(CheckScrollClaim(0, 7, false, 0, 60, 60, 1960), CLAIM_OK);
    EXPECT_STREQ(CheckScrollClaim(0, 7, false, 0, 60, 60, 1959),
        "COLLECT_SCROLL_OF_FORTUNE_REWARDS_NOT_ENOUGH_MARKS_OF_ASCENSION");
    EXPECT_STREQ(CheckScrollClaim(0, 7, false, 0, 59, 60, 1960), "COLLECT_SCROLL_OF_FORTUNE_REWARDS_TOO_LOW_LEVEL");
    EXPECT_STREQ(CheckScrollClaim(0, 1, false, ENDGAME_SCROLL_CLAIMS - 1, 60, 60, 22250), CLAIM_OK);
    EXPECT_STREQ(CheckScrollClaim(0, 1, false, ENDGAME_SCROLL_CLAIMS, 60, 60, 100000),
        "COLLECT_SCROLL_OF_FORTUNE_REWARDS_INVALID_COUNT");
    EXPECT_STREQ(CheckScrollClaim(0, 0, false, 0, 60, 60, 100000), "COLLECT_SCROLL_OF_FORTUNE_REWARDS_INVALID_COUNT");
}

TEST(AscensionWildcardTest, TheRewardListCarriesTheLevelingMilestonesAndTheEndgameClaimsOfEverySpec)
{
    std::size_t const recordSize = 0x31;
    std::size_t const perSpec = LEVELING_REWARDS.size() + ENDGAME_SCROLL_CLAIMS;
    std::vector<std::uint8_t> const payload = ScrollRewardsPayload(60);
    ASSERT_EQ(payload.size(), sizeof(std::uint32_t) + SPECIALIZATION_COUNT * perSpec * recordSize);
    EXPECT_EQ(ReadUInt32(payload, 0), SPECIALIZATION_COUNT * perSpec);

    std::size_t const second = sizeof(std::uint32_t) + recordSize;
    EXPECT_EQ(ReadUInt32(payload, second), 0u);
    EXPECT_EQ(payload[second + 4], 1u);
    EXPECT_EQ(ReadUInt32(payload, second + 5), 20u);
    EXPECT_EQ(ReadUInt32(payload, second + 9), SCROLL_OF_FORTUNE_ITEMS[0]);
    EXPECT_EQ(ReadUInt32(payload, second + 13), TALENT_SCROLL_OF_FORTUNE_ITEM);
    EXPECT_EQ(ReadUInt32(payload, second + 17), 0u);
    EXPECT_EQ(ReadUInt32(payload, second + 0x19), 4u);
    EXPECT_EQ(ReadUInt32(payload, second + 0x1D), 8u);
    EXPECT_EQ(ReadUInt32(payload, second + 0x29), 0u);
    EXPECT_EQ(ReadUInt32(payload, second + 0x2D), 0u);

    std::size_t const endgame = sizeof(std::uint32_t) + LEVELING_REWARDS.size() * recordSize;
    EXPECT_EQ(ReadUInt32(payload, endgame), 0u);
    EXPECT_EQ(payload[endgame + 4], 0u);
    EXPECT_EQ(ReadUInt32(payload, endgame + 5), 60u);
    EXPECT_EQ(ReadUInt32(payload, endgame + 9), SCROLL_OF_FORTUNE_ITEMS[0]);
    EXPECT_EQ(ReadUInt32(payload, endgame + 13), TALENT_SCROLL_OF_FORTUNE_ITEM);
    EXPECT_EQ(ReadUInt32(payload, endgame + 17), CARD_PACKS[0].Item);
    EXPECT_EQ(ReadUInt32(payload, endgame + 21), CARD_PACKS[2].Item);
    EXPECT_EQ(ReadUInt32(payload, endgame + 0x19), 1u);
    EXPECT_EQ(ReadUInt32(payload, endgame + 0x1D), 2u);
    EXPECT_EQ(ReadUInt32(payload, endgame + 0x29), 250u);
    EXPECT_EQ(ReadUInt32(payload, endgame + 0x2D), 0u);

    std::size_t const lastOfSecondSpec = sizeof(std::uint32_t) + (2 * perSpec - 1) * recordSize;
    EXPECT_EQ(ReadUInt32(payload, lastOfSecondSpec), 1u);
    EXPECT_EQ(ReadUInt32(payload, lastOfSecondSpec + 9), SCROLL_OF_FORTUNE_ITEMS[1]);
    EXPECT_EQ(ReadUInt32(payload, lastOfSecondSpec + 0x29), EndgameScrollClaimCost(ENDGAME_SCROLL_CLAIMS));
}

TEST(AscensionWildcardTest, PrestigedScrollsAreRepurchasedPerKindForRunesOrGold)
{
    EXPECT_EQ(ScrollItem(0, SCROLL_GENERIC), SCROLL_OF_FORTUNE_ITEMS[0]);
    EXPECT_EQ(ScrollItem(3, SCROLL_ABILITIES), ABILITY_SCROLL_OF_FORTUNE_ITEM + 3);
    EXPECT_EQ(ScrollItem(19, SCROLL_TALENTS), TALENT_SCROLL_OF_FORTUNE_ITEM + 19);

    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, 2, false, 32, 60, 60, 100, 0), REPURCHASE_OK);
    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, 2, false, 32, 60, 60, 99, 0), "REPURCHASE_WILDCARD_ROLL_NO_TOKENS");
    EXPECT_STREQ(CheckRepurchase(SCROLL_TALENTS, 3, false, 51, 60, 60, 99, 0), REPURCHASE_OK);
    EXPECT_STREQ(CheckRepurchase(SCROLL_TALENTS, 2, true, 51, 60, 60, 0, 300000), REPURCHASE_OK);
    EXPECT_STREQ(CheckRepurchase(SCROLL_ABILITIES, 2, true, 51, 60, 60, 0, 399999),
        "REPURCHASE_WILDCARD_ROLL_NO_MONEY");
    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, 1, false, 0, 60, 60, 100, 0), "REPURCHASE_WILDCARD_ROLL_NO_COUNT");
    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, 1, false, 5, 59, 60, 100, 0),
        "REPURCHASE_WILDCARD_ROLL_NOT_MAX_LEVEL");
    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, 0, false, 5, 60, 60, 100, 0),
        "REPURCHASE_WILDCARD_ROLL_TOO_LOW_COUNT");
    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, 6, false, 5, 60, 60, 1000, 0),
        "REPURCHASE_WILDCARD_ROLL_NOT_ENOUGH_COUNT");
    EXPECT_STREQ(CheckRepurchase(SCROLL_GENERIC, REPURCHASE_PRICES[SCROLL_GENERIC].Limit + 1, false, 20000, 60, 60,
        UINT32_MAX, 0), "REPURCHASE_WILDCARD_ROLL_TOO_HIGH_COUNT");
}

TEST(AscensionWildcardTest, CreaturesDropAnyNormalCardAtTheDropChance)
{
    Tables tables;
    EXPECT_FALSE(RollCardDrop(tables, Fixed(0)));
    tables.DropItems = { 500, 501, 502 };
    EXPECT_EQ(RollCardDrop(tables, Sequence({ CARD_DROP_CHANCE_PER_MILLE - 1, 2 })), 502u);
    EXPECT_EQ(RollCardDrop(tables, Sequence({ 0, 0 })), 500u);
    EXPECT_FALSE(RollCardDrop(tables, Sequence({ CARD_DROP_CHANCE_PER_MILLE, 0 })));

    std::mt19937 rng(7);
    std::uint32_t drops = 0;
    for (std::uint32_t kill = 0; kill < 100000; ++kill)
        drops += RollCardDrop(tables, Seeded(rng)).has_value();
    EXPECT_NEAR(drops, 100000 * CARD_DROP_CHANCE_PER_MILLE / 1000, 300);
}

Tables CardTables()
{
    Tables tables{ {}, HeroBudget(), {} };
    tables.StarterCards[100] = { 1, false };
    tables.StarterCards[101] = { 1, true };
    tables.StarterCards[200] = { 2, false };
    tables.StarterCards[301] = { 3, true };
    return tables;
}

TEST(AscensionWildcardTest, StarterCardSlotsMapToTheFourStartingPositions)
{
    EXPECT_EQ(StarterCardPosition(SKILL_CARD_STARTER_NORMAL, 0), 0u);
    EXPECT_EQ(StarterCardPosition(SKILL_CARD_STARTER_NORMAL, 1), 1u);
    EXPECT_EQ(StarterCardPosition(SKILL_CARD_STARTER_GOLDEN, 0), 2u);
    EXPECT_EQ(StarterCardPosition(SKILL_CARD_STARTER_GOLDEN, 1), 3u);
    EXPECT_FALSE(StarterCardPosition(SKILL_CARD_STARTER_GOLDEN, 2));
    EXPECT_FALSE(StarterCardPosition(SKILL_CARD_DEFAULT_NORMAL, 0));
}

TEST(AscensionWildcardTest, StarterCardsAreSetFromTheCollectionDuringTheStartingPhase)
{
    Tables const tables = CardTables();
    StarterCardSlots cards{};
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 0, 100), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetStarterCard(tables, Abilities(4), cards, 2, 101), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 0, 999), "SET_SKILL_CARD_NOT_COLLECTED");
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 0, 101), "SET_SKILL_CARD_UNKNOWN");
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 3, 200), "SET_SKILL_CARD_UNKNOWN");
    EXPECT_STREQ(CheckSetStarterCard(tables, Abilities(5), cards, 0, 100),
        "SET_SKILL_CARD_WILDCARD_STARTING_PHASE_COMPLETE");

    cards[0] = { 100, false };
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 2, 101), "SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED");
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 1, 200), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetStarterCard(tables, {}, cards, 0, 200), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetStarterCard(tables, Abilities(5), cards, 0, 0), "SET_SKILL_CARD_OK");
}

TEST(AscensionWildcardTest, OnlyUnusedStarterCardsChooseTheNextStartingRoll)
{
    Tables const tables = CardTables();
    StarterCardSlots cards{};
    cards[0] = { 100, false };
    cards[2] = { 301, true };
    cards[3] = { 999, false };
    EXPECT_EQ(ChosenStarters(tables, cards), (std::array<std::uint32_t, STARTING_ABILITY_COUNT>{ 1, 0, 0, 0 }));
}

TEST(AscensionWildcardTest, ChosenStartersTakeTheirPositionsAndTheRestIsRolled)
{
    auto const& pool = AscensionWildcardStarterData::OtherAbilities;
    std::array<std::uint32_t, STARTING_ABILITY_COUNT> const chosen = { pool[3].EntryId, 0, pool[7].EntryId, 0 };
    std::mt19937 rng(9);
    for (int roll = 0; roll < 200; ++roll)
    {
        std::vector<Slot> const slots = RollStartingAbilities({}, Seeded(rng), Any, chosen);
        ASSERT_EQ(slots.size(), STARTING_ABILITY_COUNT);
        EXPECT_EQ(slots[0].EntryId, pool[3].EntryId);
        EXPECT_EQ(slots[2].EntryId, pool[7].EntryId);
        EXPECT_TRUE(Contains(pool, slots[1].EntryId) && Contains(pool, slots[3].EntryId));
        std::set<std::uint32_t> const distinct = { slots[0].EntryId, slots[1].EntryId, slots[2].EntryId,
            slots[3].EntryId };
        EXPECT_EQ(distinct.size(), STARTING_ABILITY_COUNT);
    }

    std::vector<Slot> locked = RollStartingAbilities({}, Seeded(rng), Any);
    locked[0].Locked = true;
    EXPECT_EQ(RollStartingAbilities(locked, Seeded(rng), Any, chosen)[0].EntryId, locked[0].EntryId);
}

Tables RollCardTables()
{
    Tables tables{ { Ability(101, 10), Ability(102, 30), Ability(103, 10), Talent(201, 10, 3) }, HeroBudget() };
    tables.Cards[700] = { 101, SKILL_CARD_DEFAULT_NORMAL, 1 };
    tables.Cards[701] = { 102, SKILL_CARD_DEFAULT_NORMAL, 1 };
    tables.Cards[702] = { 103, SKILL_CARD_DEFAULT_GOLDEN, 1 };
    tables.Cards[710] = { 201, SKILL_CARD_TALENT_NORMAL, 3 };
    return tables;
}

TEST(AscensionWildcardTest, AbilityAndTalentCardSlotsMapToTheirTypes)
{
    EXPECT_EQ(RollCardPosition(SKILL_CARD_DEFAULT_NORMAL, 0), 0u);
    EXPECT_EQ(RollCardPosition(SKILL_CARD_DEFAULT_GOLDEN, 2), 5u);
    EXPECT_EQ(RollCardPosition(SKILL_CARD_TALENT_NORMAL, 0), 6u);
    EXPECT_EQ(RollCardPosition(SKILL_CARD_TALENT_GOLDEN, 2), 11u);
    EXPECT_FALSE(RollCardPosition(SKILL_CARD_DEFAULT_NORMAL, 3));
    EXPECT_FALSE(RollCardPosition(SKILL_CARD_STARTER_NORMAL, 0));
    EXPECT_FALSE(RollCardPosition(SKILL_CARD_LUCKY_NORMAL, 0));
}

TEST(AscensionWildcardTest, AbilityAndTalentCardsAreSetBetweenTheStartersAndTheFifthSpell)
{
    Tables const tables = RollCardTables();
    CardCollection const collection{ { 700, 701, 702, 710 }, {} };
    RollCardSlots cards{};
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 0, 700), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 6, 710), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(3), cards, collection, 0, 700), "SET_SKILL_CARD_UNKNOWN");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(5), cards, collection, 0, 700),
        "SET_SKILL_CARD_WILDCARD_STARTING_PHASE_COMPLETE");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(5), cards, collection, 0, 0),
        "SET_SKILL_CARD_WILDCARD_STARTING_PHASE_COMPLETE");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 3, 700), "SET_SKILL_CARD_UNKNOWN");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 0, 710), "SET_SKILL_CARD_UNKNOWN");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, CardCollection{}, 0, 700),
        "SET_SKILL_CARD_NOT_COLLECTED");

    std::vector<Slot> starters = Abilities(3);
    starters.push_back({ 101 });
    EXPECT_STREQ(CheckSetRollCard(tables, starters, cards, collection, 0, 700),
        "SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED");
    cards[0] = { 700, false };
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 1, 700),
        "SET_SKILL_CARD_ENTRY_ALREADY_ACTIVATED");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 0, 701), "SET_SKILL_CARD_OK");
    EXPECT_STREQ(CheckSetRollCard(tables, Abilities(4), cards, collection, 0, 0), "SET_SKILL_CARD_OK");
}

TEST(AscensionWildcardTest, SlottedCardsGuaranteeTheirEntryOnceItsLevelIsReached)
{
    Tables const tables = RollCardTables();
    RollCardSlots cards{};
    cards[0] = { 701, false };
    cards[1] = { 700, false };
    cards[3] = { 702, false };
    cards[6] = { 710, false };

    std::vector<Slot> const carded = CardedEntries(tables, cards, 10);
    ASSERT_EQ(carded.size(), 3u);
    EXPECT_EQ(carded[0].EntryId, 102u);
    EXPECT_EQ(carded[1].EntryId, 103u);
    EXPECT_EQ(carded[2].EntryId, 201u);
    EXPECT_EQ(carded[2].Rank, 3u);
    EXPECT_TRUE(carded[2].Talent);
    EXPECT_EQ(CardedEntries(tables, cards, 25).size(), 4u);

    EXPECT_EQ(RollLevelEntry(tables, Abilities(4), 10, 0, Fixed(0), Any, carded)->EntryId, 103u);
    std::optional<Slot> const talent = RollLevelEntry(tables, Abilities(5), 11, 0, Fixed(0), Any, carded);
    ASSERT_TRUE(talent);
    EXPECT_EQ(talent->EntryId, 201u);
    EXPECT_EQ(talent->Rank, 3u);

    cards[3].Used = true;
    std::vector<Slot> leveled = Abilities(14);
    for (std::uint32_t entryId = 301; entryId <= 310; ++entryId)
        leveled.push_back(TalentSlot(entryId));
    EXPECT_EQ(RollLevelEntry(tables, leveled, 30, 0, Fixed(0), Any, CardedEntries(tables, cards, 30))->EntryId,
        102u);
    EXPECT_EQ(RollLevelEntry(tables, leveled, 30, 0, Fixed(0), Any)->EntryId, 101u);
}

TEST(AscensionWildcardTest, SkillCardPayloadsListTheSlotsAndTheCollection)
{
    Tables tables = RollCardTables();
    StarterCardSlots cards{};
    cards[1] = { 200, true };
    cards[2] = { 301, false };
    RollCardSlots rollCards{};
    rollCards[1] = { 701, false };
    rollCards[6] = { 710, true };
    std::vector<std::uint8_t> const payload = SkillCardSlotsPayload(tables, { {}, { cards, rollCards } });
    std::size_t offset = sizeof(std::uint32_t);
    std::vector<std::vector<std::array<std::uint32_t, 3>>> types;
    for (std::size_t block = 0; block < 2 * SKILL_CARD_TYPE_COUNT; ++block)
    {
        std::uint32_t const count = ReadUInt32(payload, offset);
        offset += sizeof(std::uint32_t);
        types.emplace_back();
        for (std::uint32_t slot = 0; slot < count; ++slot, offset += 9)
            types.back().push_back({ ReadUInt32(payload, offset), ReadUInt32(payload, offset + 4),
                payload[offset + 8] });
    }
    ASSERT_EQ(offset, payload.size());
    EXPECT_EQ(ReadUInt32(payload, 0), 2u);
    EXPECT_EQ(types[SKILL_CARD_DEFAULT_NORMAL], (std::vector<std::array<std::uint32_t, 3>>(3)));
    types.erase(types.begin(), types.begin() + SKILL_CARD_TYPE_COUNT);
    EXPECT_EQ(types[SKILL_CARD_DEFAULT_NORMAL], (std::vector<std::array<std::uint32_t, 3>>{ { 0, 0, 0 },
        { 701, 1, 0 }, { 0, 0, 0 } }));
    EXPECT_EQ(types[SKILL_CARD_TALENT_NORMAL], (std::vector<std::array<std::uint32_t, 3>>{ { 710, 3, 1 },
        { 0, 0, 0 }, { 0, 0, 0 } }));
    EXPECT_TRUE(types[SKILL_CARD_MAX_TYPE].empty());
    EXPECT_EQ(types[SKILL_CARD_STARTER_NORMAL], (std::vector<std::array<std::uint32_t, 3>>{ { 0, 0, 0 },
        { 200, 1, 1 } }));
    EXPECT_EQ(types[SKILL_CARD_STARTER_GOLDEN], (std::vector<std::array<std::uint32_t, 3>>{ { 301, 1, 0 },
        { 0, 0, 0 } }));

    tables = CardTables();
    tables.Cards[500] = { 0, SKILL_CARD_TALENT_NORMAL, 3 };
    CardCollection owned{ { 500, 100 } };
    owned.Progress[500] = 8;
    owned.BonusProgress = 37;
    owned.Purchases[7] = 2;
    std::vector<std::uint8_t> const collection = SkillCardCollectionPayload(tables, owned);
    std::size_t const records = sizeof(std::uint32_t) * (1 + SEALED_CARD_TYPE_COUNT);
    ASSERT_EQ(collection.size(), records + sizeof(std::uint32_t) + 5 * 12u);
    EXPECT_EQ(ReadUInt32(collection, 0), 37u);
    EXPECT_EQ(ReadUInt32(collection, sizeof(std::uint32_t) * (1 + 7)), 2u);
    EXPECT_EQ(ReadUInt32(collection, records), 5u);
    std::map<std::uint32_t, std::array<std::uint32_t, 2>> collected;
    for (std::size_t offset = records + 4; offset < collection.size(); offset += 12)
        collected[ReadUInt32(collection, offset)] = { ReadUInt32(collection, offset + 4),
            ReadUInt32(collection, offset + 8) };
    EXPECT_EQ(collected, (std::map<std::uint32_t, std::array<std::uint32_t, 2>>{ { 100, { 0, 1 } },
        { 101, { 0, 1 } }, { 200, { 0, 1 } }, { 301, { 0, 1 } }, { 500, { 8, 3 } } }));
}

TEST(AscensionWildcardTest, PacksDrawFiveDifferentCardsOfTheirTypeCollectedOrNot)
{
    Tables tables = CardTables();
    for (std::uint32_t card = 500; card < 507; ++card)
        tables.PackCards[SKILL_CARD_TALENT_NORMAL].push_back(card);
    tables.PackCards[SKILL_CARD_DEFAULT_NORMAL] = { 900 };
    std::mt19937 rng(4);
    std::set<std::uint32_t> seen;
    for (int pack = 0; pack < 50; ++pack)
    {
        std::vector<std::uint32_t> const opened = OpenCardPack(tables, SKILL_CARD_TALENT_NORMAL, Seeded(rng));
        ASSERT_EQ(opened.size(), CARDS_PER_PACK);
        EXPECT_EQ(std::set<std::uint32_t>(opened.begin(), opened.end()).size(), CARDS_PER_PACK);
        seen.insert(opened.begin(), opened.end());
    }
    EXPECT_EQ(seen, (std::set<std::uint32_t>{ 500, 501, 502, 503, 504, 505, 506 }));
    EXPECT_EQ(OpenCardPack(tables, SKILL_CARD_DEFAULT_NORMAL, Seeded(rng)), (std::vector<std::uint32_t>{ 900 }));
}

TEST(AscensionWildcardTest, PendingCardsAreNumberedForTheClient)
{
    CardCollection collection;
    AddPending(collection, { 600, 7 });
    collection.Pending.erase(collection.Pending.begin());
    AddPending(collection, { 600 });
    ASSERT_EQ(collection.Pending.size(), 2u);
    EXPECT_EQ(collection.Pending[0].Id, 2u);
    EXPECT_EQ(collection.Pending[1].Id, 3u);

    Tables tables = CardTables();
    tables.Cards[600] = { 0, SKILL_CARD_TALENT_NORMAL, 2 };
    std::vector<std::uint8_t> const payload = PendingCardsPayload(tables, collection.Pending);
    ASSERT_EQ(payload.size(), 24u);
    EXPECT_EQ(ReadUInt32(payload, 0), 2u);
    EXPECT_EQ(std::string(reinterpret_cast<char const*>(payload.data() + 4)), PendingCardName(2));
    EXPECT_EQ(ReadUInt32(payload, 6), 7u);
    EXPECT_EQ(ReadUInt32(payload, 10), 1u);
    EXPECT_EQ(std::string(reinterpret_cast<char const*>(payload.data() + 14)), PendingCardName(3));
    EXPECT_EQ(ReadUInt32(payload, 16), 600u);
    EXPECT_EQ(ReadUInt32(payload, 20), 2u);
}

TEST(AscensionWildcardTest, RevealedCardsPayTicketsAndDuplicatesFillTheBonusPack)
{
    Tables tables = CardTables();
    tables.Cards[800] = { 0, SKILL_CARD_DEFAULT_NORMAL, 1, SKILL_CARD_EPIC };
    tables.Cards[801] = { 0, SKILL_CARD_TALENT_GOLDEN, 1, SKILL_CARD_LEGENDARY };
    tables.Cards[802] = { 0, SKILL_CARD_TALENT_NORMAL, 3, SKILL_CARD_RARE };
    CardCollection collection{ { 800, 802 } };
    collection.BonusProgress = 95;
    AddPending(collection, { 800, 801, 802, 801 });

    CardClaim const claim = ClaimPendingCards(tables, collection, { 1, 2, 3, 9 }, Fixed(2));
    ASSERT_EQ(claim.Claimed.size(), 3u);
    EXPECT_EQ(claim.Tickets, 2u);
    EXPECT_EQ(claim.GoldenTickets, 1u);
    EXPECT_TRUE(collection.Collected.contains(801));
    EXPECT_EQ(collection.Progress[802], DUPLICATE_PROGRESS[SKILL_CARD_RARE]);
    EXPECT_EQ(claim.BonusPacks, (std::vector<std::uint32_t>{ CARD_PACKS[2].Item }));
    EXPECT_EQ(collection.BonusProgress, 95 + DUPLICATE_PROGRESS[SKILL_CARD_EPIC] - BONUS_PACK_PROGRESS);
    ASSERT_EQ(collection.Pending.size(), 1u);
    EXPECT_EQ(collection.Pending[0].Id, 4u);

    CardClaim const golden = ClaimPendingCards(tables, collection, { 4 }, Fixed(0));
    EXPECT_EQ(golden.GoldenTickets, 1u);
    EXPECT_TRUE(golden.BonusPacks.empty());
    EXPECT_EQ(collection.BonusProgress, 3 + DUPLICATE_PROGRESS[SKILL_CARD_LEGENDARY]);
    EXPECT_TRUE(ClaimPendingCards(tables, collection, { 4 }, Fixed(0)).Claimed.empty());
}

TEST(AscensionWildcardTest, TicketsBuyThreeUncollectedCardsOfARarityAtRisingPrices)
{
    std::size_t const rareTalents = 7;
    ASSERT_STREQ(SEALED_CARD_TYPE_NAMES[rareTalents], "PURCHASE_SEALED_CARD_TYPE_NORMAL_RARE_TALENTS");
    Tables tables = CardTables();
    for (std::uint32_t card = 820; card < 826; ++card)
    {
        tables.Cards[card] = { 0, SKILL_CARD_TALENT_NORMAL, 1, card < 824 ? SKILL_CARD_RARE : SKILL_CARD_EPIC };
        tables.PackCards[SKILL_CARD_TALENT_NORMAL].push_back(card);
    }
    tables.SealedCosts.resize(2);
    tables.SealedCosts[0][rareTalents] = 200;
    tables.SealedCosts[1][rareTalents] = 400;
    CardCollection collection{ { 820 } };
    std::mt19937 rng(3);

    SealedPurchase const bought = CheckSealedPurchase(tables, collection, rareTalents, 1, 200, Seeded(rng));
    EXPECT_STREQ(bought.Result, "PURCHASE_SEALED_CARD_OK");
    EXPECT_EQ(bought.Token, DARKMOON_TICKET_ITEM);
    EXPECT_EQ(bought.Cost, 200u);
    EXPECT_EQ(std::set<std::uint32_t>(bought.Cards.begin(), bought.Cards.end()),
        (std::set<std::uint32_t>{ 821, 822, 823 }));

    collection.Purchases[rareTalents] = 1;
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, rareTalents, 1, 399, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_NO_TOKEN");
    EXPECT_EQ(CheckSealedPurchase(tables, collection, rareTalents, 1, 400, Seeded(rng)).Cost, 400u);
    collection.Purchases[rareTalents] = 2;
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, rareTalents, 1, 1000, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_NO_COST_ENTRY");
    collection.Purchases[rareTalents] = 0;
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, rareTalents - 1, 1, 1000, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_BAD_COST");
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, rareTalents, 2, 1000, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_BAD_AMOUNT");
    collection.Collected.insert({ 821, 822, 823 });
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, rareTalents, 1, 1000, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_NO_UNCOLLECTED_CARDS_OF_QUALITY");
    collection.Collected.erase(821);
    AddPending(collection, { 900 });
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, rareTalents, 1, 1000, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_UNCLAIMED_CARDS");
    EXPECT_STREQ(CheckSealedPurchase(tables, collection, 20, 1, 1000, Seeded(rng)).Result,
        "PURCHASE_SEALED_CARD_BAD_TYPE");
    EXPECT_EQ(SealedCardToken(17), GOLDEN_DARKMOON_TICKET_ITEM);
}

TEST(AscensionWildcardTest, SilasSellsCommonToEpicCardsForTicketsOfTheirKind)
{
    Tables tables = CardTables();
    tables.Cards[830] = { 0, SKILL_CARD_DEFAULT_NORMAL, 1, SKILL_CARD_COMMON };
    tables.Cards[831] = { 0, SKILL_CARD_TALENT_NORMAL, 3, SKILL_CARD_EPIC };
    tables.Cards[832] = { 0, SKILL_CARD_DEFAULT_NORMAL, 1, SKILL_CARD_LEGENDARY };
    tables.Cards[833] = { 0, SKILL_CARD_TALENT_GOLDEN, 1, SKILL_CARD_RARE };
    tables.Cards[100] = { 1, SKILL_CARD_DEFAULT_NORMAL, 1, SKILL_CARD_COMMON };
    tables.CardItems = { { 9830, 830 }, { 9831, 831 }, { 9832, 832 }, { 9833, 833 }, { 9100, 100 } };

    std::vector<StoreCard> const normal = SkillCardStore(tables, SKILL_CARD_STORE);
    ASSERT_EQ(normal.size(), 2u);
    EXPECT_EQ(normal[0].Item, 9830u);
    EXPECT_EQ(normal[0].Token, DARKMOON_TICKET_ITEM);
    EXPECT_EQ(normal[0].Price, SKILL_CARD_STORE_PRICE);
    EXPECT_EQ(normal[1].Item, 9831u);
    EXPECT_EQ(normal[1].Price, SKILL_CARD_STORE_PRICE);
    std::vector<StoreCard> const golden = SkillCardStore(tables, GOLDEN_SKILL_CARD_STORE);
    ASSERT_EQ(golden.size(), 1u);
    EXPECT_EQ(golden[0].Token, GOLDEN_DARKMOON_TICKET_ITEM);
    EXPECT_EQ(golden[0].Price, SKILL_CARD_STORE_PRICE);
    EXPECT_TRUE(SkillCardStore(tables, 4).empty());

    std::vector<std::uint8_t> const payload = CustomStorePayload(SKILL_CARD_STORE, normal);
    std::size_t const records = std::string("QUERY_CUSTOM_STORE_OK").size() + 1 + sizeof(std::uint32_t);
    ASSERT_EQ(payload.size(), records + 2 * 64u);
    EXPECT_EQ(std::string(reinterpret_cast<char const*>(payload.data())), "QUERY_CUSTOM_STORE_OK");
    EXPECT_EQ(ReadUInt32(payload, records - 4), 2u);
    EXPECT_EQ(ReadUInt32(payload, records), 9830u);
    EXPECT_EQ(ReadUInt32(payload, records + 4), SKILL_CARD_STORE);
    EXPECT_EQ(ReadUInt32(payload, records + 8), 9830u);
    EXPECT_EQ(ReadUInt32(payload, records + 12), 0u);
    EXPECT_EQ(ReadUInt32(payload, records + 16), DARKMOON_TICKET_ITEM);
    EXPECT_EQ(ReadUInt32(payload, records + 36), SKILL_CARD_STORE_PRICE);
    EXPECT_EQ(ReadUInt32(payload, records + 64 + 36), SKILL_CARD_STORE_PRICE);
}

TEST(AscensionWildcardTest, SilasSellsTheDarkmoonPrizesForTicketsByKind)
{
    std::vector<StoreCard> const prizes = DarkmoonPrizeStore();
    ASSERT_EQ(prizes.size(), 37u);
    EXPECT_TRUE(std::all_of(prizes.begin(), prizes.end(),
        [](StoreCard const& prize) { return prize.Token == DARKMOON_TICKET_ITEM; }));
    auto const price = [&prizes](std::uint32_t item)
    {
        auto const prize = std::find_if(prizes.begin(), prizes.end(),
            [item](StoreCard const& offer) { return offer.Item == item; });
        return prize == prizes.end() ? 0u : prize->Price;
    };
    EXPECT_EQ(price(73764), DARKMOON_PRIZE_PRICE_PETS_AND_ACCESSORIES);
    EXPECT_EQ(price(499321), DARKMOON_PRIZE_PRICE_PETS_AND_ACCESSORIES);
    EXPECT_EQ(price(78341), DARKMOON_PRIZE_PRICE_TRANSMOG);
    EXPECT_EQ(price(263033), DARKMOON_PRIZE_PRICE_TRANSMOG);
    EXPECT_EQ(price(246192), DARKMOON_PRIZE_PRICE_MOUNTS_AND_TOYS);
    EXPECT_EQ(price(998100), DARKMOON_PRIZE_PRICE_MOUNTS_AND_TOYS);
}

TEST(AscensionWildcardTest, CollectedCardsAreNewOrFillTheBonusPackWithAnyOfTheFourPacks)
{
    Tables tables = CardTables();
    tables.Cards[840] = { 0, SKILL_CARD_TALENT_GOLDEN, 1, SKILL_CARD_LEGENDARY };
    CardCollection collection;
    collection.BonusProgress = 90;
    EXPECT_TRUE(CollectCard(tables, collection, 840, Fixed(0)).empty());
    EXPECT_TRUE(collection.Collected.contains(840));
    EXPECT_EQ(CollectCard(tables, collection, 840, Fixed(0)), (std::vector<std::uint32_t>{ CARD_PACKS[0].Item }));
    EXPECT_EQ(collection.BonusProgress, 0u);

    std::set<std::uint32_t> packs;
    for (std::uint32_t pick = 0; pick < CARD_PACKS.size(); ++pick)
    {
        collection.BonusProgress = 90;
        std::vector<std::uint32_t> const bonus = CollectCard(tables, collection, 840, Fixed(pick));
        packs.insert(bonus.begin(), bonus.end());
    }
    EXPECT_EQ(packs.size(), CARD_PACKS.size());
}

TEST(AscensionWildcardTest, KnownEntriesCarryTheLockAndTheSlotAsLearnOrder)
{
    std::vector<Slot> const slots = { { 36459, false }, {}, { 40008, true }, { 41071, false, 3, true } };
    std::vector<std::uint8_t> const payload = AscensionCoATalentState::KnownEntriesPayload(KnownEntries(slots));

    ASSERT_EQ(payload.size(), sizeof(std::uint32_t) + 3 * 21u);
    EXPECT_EQ(ReadUInt32(payload, 0), 3u);

    KnownEntryRecord const unlocked = ReadRecord(payload, 0);
    EXPECT_EQ(unlocked.EntryId, 36459u);
    EXPECT_EQ(unlocked.Rank, 1u);
    EXPECT_EQ(unlocked.LearnedSpellRank, 1u);
    EXPECT_EQ(unlocked.Locked, 0u);
    EXPECT_EQ(unlocked.LearnOrder, 1u);
    EXPECT_EQ(unlocked.Reserved, 0u);

    KnownEntryRecord const locked = ReadRecord(payload, 1);
    EXPECT_EQ(locked.EntryId, 40008u);
    EXPECT_EQ(locked.Locked, 1u);
    EXPECT_EQ(locked.LearnOrder, 3u);

    KnownEntryRecord const talent = ReadRecord(payload, 2);
    EXPECT_EQ(talent.EntryId, 41071u);
    EXPECT_EQ(talent.Rank, 3u);
    EXPECT_EQ(talent.LearnedSpellRank, 3u);
    EXPECT_EQ(talent.LearnOrder, 4u);
}

TEST(AscensionWildcardTest, SlotsRoundTripThroughTheirStoredValue)
{
    for (Slot const slot : { Slot{ 40008, false }, Slot{ 138119, true }, Slot{}, Slot{ 41071, false, 5, true },
             Slot{ 138346, true, 3, true } })
    {
        Slot const stored = Decode(Encode(slot));
        EXPECT_EQ(stored.EntryId, slot.EntryId);
        EXPECT_EQ(stored.Locked, slot.Locked);
        EXPECT_EQ(stored.Rank, slot.Rank);
        EXPECT_EQ(stored.Talent, slot.Talent);
    }
    EXPECT_EQ(Decode(40008 | LOCKED).Rank, 1u);
    EXPECT_FALSE(Decode(40008 | LOCKED).Talent);
}

TEST(AscensionWildcardTest, StarterTablesAreConsistent)
{
    for (StarterEntry const& entry : AscensionWildcardStarterData::FirstAbility)
        EXPECT_TRUE(Contains(AscensionWildcardStarterData::OtherAbilities, entry.EntryId)) << entry.EntryId;
    for (StarterEntry const& entry : AscensionWildcardStarterData::OtherAbilities)
    {
        EXPECT_GT(entry.Weight, 0u) << entry.EntryId;
        EXPECT_EQ(SpellOf(entry.EntryId), entry.SpellId);
        EXPECT_EQ(entry.EntryId & ~ENTRY_MASK, 0u);
    }
    EXPECT_EQ(SpellOf(1), 0u);
}
