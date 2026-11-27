#include "Engine/Rules.h"
#include "Store/Journal.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <cmath>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Store;

namespace
{
    DataSet JournalData()
    {
        DataSet data;
        data.species[10] = { 10, "Young Wolf", 100, true, false, false, false, true, "Ability_Hunter_Pet_Wolf", 0.0f };
        data.species[20] = { 20, "Rat", 200, true, true, true, true, false, "Ability_Druid_Dash", 0.0f };
        data.kits[100] = { 100, "Frostwolf Pup", 7, 100, 0, -100 };
        data.kits[200] = { 200, "Rat", 4, 0, 0, 0 };
        data.defaultBreeds = { { BalancedBreed, {} }, { 5, { -50, -50, 150 } } };
        data.breeds[10] = { { 3, { 1700, 1500, 1900 } }, { 5, { 1600, 1400, 2200 } } };
        data.xp[1] = { 1, 1, 50 };
        data.xp[2] = { 2, 2, 60 };
        data.xp[3] = { 3, 3, 70 };
        data.xp[4] = { 4, 4, 80 };
        data.xp[5] = { 5, 5, 90 };
        for (uint8_t level = 6; level <= 25; ++level)
            data.xp[level] = { level, 6, 100 };
        return data;
    }

    Engine::Catalog const& JournalCatalog()
    {
        static DataSet const data = JournalData();
        static Engine::Catalog const catalog(data, Settings());
        return catalog;
    }

    OwnedPet Owned(uint32_t species, uint8_t level, uint8_t quality = 1, uint32_t revision = 0)
    {
        OwnedPet pet;
        pet.species = species;
        pet.id = species;
        pet.level = level;
        pet.quality = quality;
        pet.revision = revision;
        return pet;
    }

    Journal Make(std::vector<OwnedPet> pets, std::array<Team, TeamCount> teams = {}, uint8_t active = 1,
        uint32_t activeRevision = 0)
    {
        return Journal(7, JournalCatalog(), std::move(pets), teams, active, activeRevision);
    }

    uint32_t StatsHealth(uint32_t species, uint8_t level, uint8_t quality)
    {
        Engine::SpeciesDef const* def = JournalCatalog().Species(species);
        return static_cast<uint32_t>(Engine::PetStats(def->power, def->speed, def->stamina, level, quality, 25).health);
    }
}

TEST(CoAPetBattlesJournal, XpRewardFollowsUpstream)
{
    EXPECT_EQ(XpReward(JournalCatalog(), 1, 3), 70u);
    EXPECT_EQ(XpReward(JournalCatalog(), 3, 3), 70u);
    EXPECT_EQ(XpReward(JournalCatalog(), 6, 3), 28u);
    EXPECT_EQ(XpReward(JournalCatalog(), 8, 3), 0u);
    EXPECT_EQ(XpReward(JournalCatalog(), 1, 30), 100u);
    EXPECT_EQ(XpNeeded(JournalCatalog(), 2), 120u);
}

TEST(CoAPetBattlesJournal, GrantXpCarriesOverAndHealsOnLevelUp)
{
    OwnedPet pet = Owned(10, 1);
    pet.health = 5;
    pet.healthAt = 100;
    Journal journal = Make({ pet });
    EXPECT_EQ(journal.GrantXp(10, 5, 200), (XpGain { 90, 2, 1 }));
    EXPECT_EQ(journal.Pet(10)->xp, 40u);
    EXPECT_EQ(journal.Pet(10)->health, 0u);
    EXPECT_EQ(journal.Pet(10)->level, 2);
    EXPECT_EQ(journal.GrantXp(10, 5, 300), (XpGain { 90, 3, 1 }));
    EXPECT_EQ(journal.Pet(10)->xp, 10u);
    EXPECT_FALSE(journal.GrantXp(20, 5, 300).has_value());
}

TEST(CoAPetBattlesJournal, GrantXpAtMaxLevelGivesNothing)
{
    Journal journal = Make({ Owned(10, 25), Owned(20, 24) });
    EXPECT_EQ(journal.GrantXp(10, 25, 0), (XpGain { 0, 25, 0 }));
    journal.TakeWrites();
    for (int i = 0; i < 20; ++i)
        journal.GrantXp(20, 25, 0);
    EXPECT_EQ(journal.Pet(20)->level, 25);
    EXPECT_EQ(journal.Pet(20)->xp, 0u);
}

TEST(CoAPetBattlesJournal, HealthRegeneratesAndCaps)
{
    OwnedPet pet = Owned(10, 25, 4);
    pet.health = 10;
    pet.healthAt = 1000;
    Journal journal = Make({ pet });
    uint32_t const max = StatsHealth(10, 25, 4);
    ASSERT_EQ(journal.MaxHealth(*journal.Pet(10)), max);
    uint32_t const perTick = std::max<uint32_t>(1, max / 100);
    EXPECT_EQ(journal.CurrentHealth(*journal.Pet(10), 1035), 10 + 3 * perTick);
    EXPECT_EQ(journal.CurrentHealth(*journal.Pet(10), 1000000000), max);
    EXPECT_EQ(journal.CurrentHealth(*journal.Pet(10), 500), 10u);
    EXPECT_TRUE(journal.SetHealth(10, 0, 2000));
    EXPECT_EQ(journal.Pet(10)->health, 1u);
    EXPECT_EQ(journal.Pet(10)->healthAt, 2000u);
    EXPECT_TRUE(journal.SetHealth(10, max, 2000));
    EXPECT_EQ(journal.Pet(10)->health, 0u);
    EXPECT_EQ(journal.CurrentHealth(*journal.Pet(10), 2000), max);
    journal.SetHealth(10, 3, 2000);
    EXPECT_EQ(journal.HealAll(), 1u);
    EXPECT_EQ(journal.Pet(10)->health, 0u);
}

TEST(CoAPetBattlesJournal, EveryCaptureGetsItsOwnIdAndStats)
{
    Journal journal = Make({ Owned(10, 9, 4) });
    OwnedPet const* first = journal.Capture(10, 25, { 2, 1, 2 }, 3, 77, 5);
    OwnedPet const* second = journal.Capture(10, 25, { 2, 1, 2 }, 3, 77, 5);
    OwnedPet const* third = journal.Capture(10, 3, { 1, 1, 1 }, 1, 0, 3);
    ASSERT_NE(first, nullptr);
    ASSERT_NE(second, nullptr);
    ASSERT_NE(third, nullptr);
    EXPECT_NE(first->id, second->id);
    EXPECT_EQ(first->source, PetSource::Wild);
    EXPECT_EQ(first->breed, 5);
    EXPECT_EQ(journal.MaxHealth(*first), 1400u);
    EXPECT_EQ(third->breed, 3);
    EXPECT_EQ(journal.Pet(10)->level, 9u);
    EXPECT_EQ(journal.Pets().size(), 4u);
    EXPECT_EQ(journal.Capture(10, 3, { 1, 1, 1 }, 1, 0, 12), nullptr);
    EXPECT_EQ(journal.Capture(999, 3, { 1, 1, 1 }, 1, 0), nullptr);
    Journal reloaded = Make({ *journal.Pet(10), *first, *second, *third });
    EXPECT_EQ(reloaded.Pet(first->id)->breed, 5u);
    EXPECT_EQ(reloaded.Pet(second->id)->source, PetSource::Wild);
    EXPECT_EQ(reloaded.Pets().size(), 4u);
}

TEST(CoAPetBattlesJournal, UnusableRowsCountAsOwnedAndAreNeverWritten)
{
    OwnedPet badPick = Owned(20, 3);
    badPick.picks = { 1, 3, 1 };
    Journal journal = Make({ Owned(999, 3), Owned(10, 30), badPick });
    EXPECT_EQ(journal.Rejected().size(), 3u);
    for (uint32_t species : { 999u, 10u, 20u })
    {
        EXPECT_TRUE(journal.Owns(species)) << species;
        EXPECT_EQ(journal.Pet(species), nullptr) << species;
        EXPECT_FALSE(journal.Add(species, 1, { 1, 1, 1 }, 1, 0)) << species;
        EXPECT_FALSE(journal.SetPicks(species, { 2, 2, 2 })) << species;
        EXPECT_FALSE(journal.GrantXp(species, 25, 0).has_value()) << species;
    }
    EXPECT_TRUE(journal.Pets().empty());
    std::multimap<uint32_t, uint32_t> const companions = { { 10, 500 }, { 20, 600 } };
    EXPECT_TRUE(journal.SyncCompanions(companions, [](uint32_t) { return true; }).empty());
    EXPECT_EQ(journal.SetTeam(1, { 10, 0, 0 }), TeamResult::NotOwned);
    EXPECT_EQ(journal.BattleTeam(), (std::array<uint32_t, 3> { 0, 0, 0 }));
    EXPECT_TRUE(journal.TakeWrites().empty());
}

TEST(CoAPetBattlesJournal, LoadedTeamsHideUnusablePets)
{
    std::array<Team, TeamCount> teams {};
    teams[0].slots = { 999, 10, 0 };
    Journal journal = Make({ Owned(10, 4), Owned(999, 3) }, teams);
    EXPECT_EQ(journal.TeamAt(1).slots, (std::array<uint32_t, 3> { 0, 10, 0 }));
    EXPECT_EQ(journal.BattleTeam(), (std::array<uint32_t, 3> { 0, 10, 0 }));
    EXPECT_TRUE(journal.TakeWrites().empty());
}

TEST(CoAPetBattlesJournal, TeamsValidateAndFill)
{
    Journal journal = Make({ Owned(10, 7), Owned(20, 3) });
    EXPECT_EQ(journal.SetTeam(4, { 10, 0, 0 }), TeamResult::BadTeam);
    EXPECT_EQ(journal.SetTeam(0, { 10, 0, 0 }), TeamResult::BadTeam);
    EXPECT_EQ(journal.SetTeam(2, { 30, 0, 0 }), TeamResult::NotOwned);
    EXPECT_EQ(journal.SetTeam(2, { 10, 10, 0 }), TeamResult::Duplicate);
    EXPECT_TRUE(journal.TakeWrites().empty());
    EXPECT_EQ(journal.BattleTeam(), (std::array<uint32_t, 3> { 10, 20, 0 }));
    std::vector<RowWrite> const filled = journal.TakeWrites();
    ASSERT_EQ(filled.size(), 1u);
    EXPECT_EQ(filled[0].kind, RowKind::Team);
    EXPECT_EQ(filled[0].key, 1u);
    EXPECT_EQ(journal.BattleTeam(), (std::array<uint32_t, 3> { 10, 20, 0 }));
    EXPECT_TRUE(journal.TakeWrites().empty());
    EXPECT_EQ(journal.SetTeam(2, { 20, 0, 0 }), TeamResult::Saved);
    EXPECT_FALSE(journal.SetActiveTeam(4));
    EXPECT_TRUE(journal.SetActiveTeam(2));
    EXPECT_EQ(journal.ActiveTeam(), 2);
    EXPECT_EQ(journal.BattleTeam(), (std::array<uint32_t, 3> { 20, 0, 0 }));
}

TEST(CoAPetBattlesJournal, CompanionSyncAddsOnceAtLevelOne)
{
    Journal journal = Make({});
    std::multimap<uint32_t, uint32_t> const companions = { { 10, 500 }, { 10, 501 }, { 20, 600 }, { 30, 700 } };
    auto knows = [](uint32_t spell) { return spell == 501 || spell == 700; };
    EXPECT_EQ(journal.SyncCompanions(companions, knows), (std::vector<uint32_t> { 10 }));
    ASSERT_NE(journal.PetOfSpecies(10), nullptr);
    EXPECT_EQ(journal.PetOfSpecies(10)->level, 1);
    EXPECT_EQ(journal.PetOfSpecies(10)->quality, 1);
    EXPECT_TRUE(journal.SyncCompanions(companions, knows).empty());

    Journal leveled = Make({ Owned(10, 9) });
    EXPECT_TRUE(leveled.SyncCompanions(companions, knows).empty());
    EXPECT_EQ(leveled.Pet(10)->level, 9);
    EXPECT_EQ(leveled.Pet(10)->source, PetSource::Companion);
    EXPECT_EQ(leveled.Pets().size(), 1u);
}

TEST(CoAPetBattlesJournal, CompanionGrantCoexistsWithWildCopiesAndIsStableAcrossReload)
{
    Journal journal = Make({});
    OwnedPet const* wild = journal.Capture(20, 5, { 1, 1, 1 }, 3, 5, 5);
    ASSERT_NE(wild, nullptr);
    std::multimap<uint32_t, uint32_t> const companions = { { 20, 500 }, { 20, 501 } };
    EXPECT_EQ(journal.SyncCompanions(companions, [](uint32_t spell) { return spell == 500; }),
        (std::vector<uint32_t> { 20 }));
    ASSERT_EQ(journal.Pets().size(), 2u);
    OwnedPet const* grant = journal.Pets().back();
    EXPECT_NE(grant->id, wild->id);
    EXPECT_EQ(grant->source, PetSource::Companion);
    EXPECT_EQ(grant->level, 1u);
    EXPECT_EQ(grant->breed, BalancedBreed);
    EXPECT_EQ(journal.MaxHealth(*grant), StatsHealth(20, 1, 1));
    Journal reloaded = Make({ *wild, *grant });
    EXPECT_TRUE(reloaded.SyncCompanions(companions, [](uint32_t spell) { return spell == 501; }).empty());
    EXPECT_TRUE(reloaded.TakeWrites().empty());
    EXPECT_EQ(reloaded.Pets().size(), 2u);
}

TEST(CoAPetBattlesJournal, WritesCarryIncreasingRevisions)
{
    std::array<Team, TeamCount> teams {};
    teams[1].revision = 5;
    Journal journal = Make({ Owned(10, 3, 1, 7) }, teams, 1, 2);
    EXPECT_TRUE(journal.Add(20, 1, { 1, 1, 1 }, 1, 0));
    EXPECT_TRUE(journal.SetPicks(10, { 2, 2, 1 }));
    EXPECT_TRUE(journal.SetActiveTeam(3));
    std::vector<RowWrite> const writes = journal.TakeWrites();
    ASSERT_EQ(writes.size(), 3u);
    EXPECT_EQ(writes[0].kind, RowKind::Pet);
    EXPECT_EQ(writes[0].key, journal.PetIdForSpecies(20));
    EXPECT_NE(writes[0].key, 20u);
    EXPECT_EQ(writes[0].revision, 8u);
    EXPECT_EQ(writes[1].key, 10u);
    EXPECT_EQ(writes[1].revision, 9u);
    EXPECT_EQ(writes[2].kind, RowKind::Account);
    EXPECT_EQ(writes[2].revision, 10u);
    EXPECT_EQ(writes[2].account, 7u);
    EXPECT_EQ(journal.Pet(10)->revision, 9u);
    EXPECT_EQ(journal.ActiveRevision(), 10u);
    EXPECT_TRUE(journal.TakeWrites().empty());
    EXPECT_FALSE(journal.SetPicks(10, { 0, 1, 1 }));
    EXPECT_TRUE(journal.SetDisplayOnce(10, 55));
    EXPECT_FALSE(journal.SetDisplayOnce(10, 56));
    EXPECT_EQ(journal.Pet(10)->display, 55u);
}

TEST(CoAPetBattlesJournal, OwnedIdsKeepSameSpeciesCopiesAndTeamsIndependent)
{
    OwnedPet first = Owned(10, 5);
    first.id = 1001;
    OwnedPet second = Owned(10, 7, 3);
    second.id = 1002;
    std::array<Team, TeamCount> teams {};
    teams[0].slots = { first.id, second.id, 0 };
    Journal journal = Make({ first, second }, teams);

    ASSERT_EQ(journal.Pets().size(), 2u);
    EXPECT_EQ(journal.BattleTeam(), teams[0].slots);
    EXPECT_EQ(journal.SetTeam(2, { second.id, first.id, 0 }), TeamResult::Saved);
    EXPECT_EQ(journal.SetTeam(3, { first.id, first.id, 0 }), TeamResult::Duplicate);
    ASSERT_TRUE(journal.SetHealth(first.id, 30, 100));
    ASSERT_EQ(journal.Feed(first.id, 5, 100), FeedResult::Fed);
    ASSERT_TRUE(journal.SetPicks(second.id, { 2, 2, 2 }));
    ASSERT_TRUE(journal.SetDisplayOnce(second.id, 81));
    ASSERT_TRUE(journal.GrantXp(second.id, 7, 100));
    EXPECT_EQ(journal.Pet(first.id)->xp, 0u);
    EXPECT_EQ(journal.Pet(first.id)->picks, first.picks);
    EXPECT_EQ(journal.Pet(first.id)->display, 0u);
    EXPECT_EQ(journal.Pet(first.id)->health, 30u);
    EXPECT_EQ(journal.Pet(second.id)->health, 0u);
    EXPECT_EQ(journal.Pet(second.id)->xp, 100u);
    EXPECT_EQ(journal.Pet(second.id)->display, 81u);
    EXPECT_EQ(journal.Pet(second.id)->picks, (std::array<uint8_t, 3> { 2, 2, 2 }));
}

TEST(CoAPetBattlesJournal, ReleasePersistsIdAndProtectsCompanionAndLegacy)
{
    OwnedPet legacy = Owned(10, 8);
    OwnedPet companion = Owned(20, 1);
    companion.source = PetSource::Companion;
    Journal journal = Make({ legacy, companion });
    OwnedPet const* captured = journal.Capture(20, 2, { 1, 1, 1 }, 3, 0);
    ASSERT_NE(captured, nullptr);
    OwnedPet tombstone = *captured;
    EXPECT_FALSE(journal.Release(legacy.id));
    EXPECT_FALSE(journal.Release(companion.id));
    EXPECT_TRUE(journal.Release(captured->id));
    EXPECT_FALSE(journal.Release(tombstone.id));
    auto const writes = journal.TakeWrites();
    ASSERT_EQ(writes.size(), 2u);
    EXPECT_EQ(writes.back().kind, RowKind::Release);
    EXPECT_EQ(writes.back().key, tombstone.id);
    tombstone.source = PetSource::Released;
    tombstone.revision = writes.back().revision;
    Journal reloaded = Make({ legacy, companion, tombstone });
    EXPECT_EQ(reloaded.Pet(tombstone.id), nullptr);
    EXPECT_TRUE(reloaded.Rejected().empty());
    auto const* next = reloaded.Capture(20, 2, { 1, 1, 1 }, 3, 0);
    ASSERT_NE(next, nullptr);
    EXPECT_GT(next->id, tombstone.id);
}
