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

TEST(CoAPetBattlesJournal, CaptureKeepsTheBetterPet)
{
    Journal journal = Make({ Owned(10, 5, 2) });
    EXPECT_EQ(journal.Compare(10, 2, 5), 2);
    EXPECT_EQ(journal.Capture(10, 5, { 1, 1, 1 }, 2, 0), CaptureResult::Released);
    EXPECT_EQ(journal.Compare(10, 1, 25), 2);
    EXPECT_EQ(journal.Capture(10, 25, { 1, 1, 1 }, 1, 0), CaptureResult::Released);
    EXPECT_EQ(journal.Compare(10, 2, 6), 1);
    EXPECT_EQ(journal.Capture(10, 6, { 2, 1, 2 }, 2, 0), CaptureResult::Replaced);
    EXPECT_EQ(journal.Pet(10)->level, 6);
    EXPECT_EQ(journal.Pet(10)->picks, (std::array<uint8_t, 3> { 2, 1, 2 }));
    EXPECT_EQ(journal.Compare(20, 1, 1), 0);
    EXPECT_EQ(journal.Capture(20, 3, { 1, 1, 1 }, 1, 0), CaptureResult::Added);
    EXPECT_EQ(journal.Compare(20, 3, 30), 1);
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
        EXPECT_EQ(journal.Compare(species, 4, 25), 2) << species;
        EXPECT_FALSE(journal.Add(species, 1, { 1, 1, 1 }, 1, 0)) << species;
        EXPECT_EQ(journal.Capture(species, 25, { 1, 1, 1 }, 4, 0), CaptureResult::Released) << species;
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
    ASSERT_NE(journal.Pet(10), nullptr);
    EXPECT_EQ(journal.Pet(10)->level, 1);
    EXPECT_EQ(journal.Pet(10)->quality, 1);
    EXPECT_TRUE(journal.SyncCompanions(companions, knows).empty());

    Journal leveled = Make({ Owned(10, 9) });
    EXPECT_TRUE(leveled.SyncCompanions(companions, knows).empty());
    EXPECT_EQ(leveled.Pet(10)->level, 9);
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
    EXPECT_EQ(writes[0].key, 20u);
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
