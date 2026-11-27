#include "Store/AccountRefs.h"
#include "Store/JournalSql.h"
#include "Store/LearnQueue.h"
#include <gtest/gtest.h>
#include <string>
#include <thread>
#include <vector>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Store;

namespace
{
    Engine::Catalog const& SqlCatalog()
    {
        static DataSet const data = []
        {
            DataSet d;
            d.species[10] = { 10, "Young Wolf", 100, true, false, false, false, true, "Ability_Hunter_Pet_Wolf", 0.0f };
            d.kits[100] = { 100, "Frostwolf Pup", 7, 100, 0, -100 };
            return d;
        }();
        static Engine::Catalog const catalog(data, Settings());
        return catalog;
    }

    size_t Count(std::string const& text, std::string const& part)
    {
        size_t count = 0;
        for (size_t at = text.find(part); at != std::string::npos; at = text.find(part, at + part.size()))
            ++count;
        return count;
    }

    std::string const Guard = "IF(VALUES(`revision`) > `revision`";
    std::string const RevisionLast = "`revision` = IF(VALUES(`revision`) > `revision`, VALUES(`revision`), `revision`)";

    bool EndsWith(std::string const& text, std::string const& tail)
    {
        return text.size() >= tail.size() && text.compare(text.size() - tail.size(), tail.size(), tail) == 0;
    }
}

TEST(CoAPetBattlesStore, UpsertGuardsEveryColumnByRevision)
{
    OwnedPet pet;
    pet.species = 10;
    pet.id = 501;
    pet.source = PetSource::Companion;
    pet.level = 4;
    pet.xp = 33;
    pet.picks = { 2, 1, 2 };
    pet.quality = 3;
    pet.display = 77;
    pet.health = 120;
    pet.healthAt = 5000;
    Journal journal(42, SqlCatalog(), { pet }, {}, 1, 0);
    ASSERT_TRUE(journal.SetPicks(501, { 2, 2, 2 }));
    ASSERT_EQ(journal.SetTeam(2, { 501, 0, 0 }), TeamResult::Saved);
    ASSERT_TRUE(journal.SetActiveTeam(2));
    std::vector<RowWrite> const writes = journal.TakeWrites();
    ASSERT_EQ(writes.size(), 3u);

    std::string const petSql = UpsertStatement(journal, writes[0]);
    EXPECT_NE(petSql.find("INSERT INTO `coa_pet_journal` (`account`, `pet_id`, `species`"), std::string::npos) << petSql;
    EXPECT_NE(petSql.find("VALUES (42, 501, 10, 4, 33, 2, 2, 2, 3, 77, 120, 5000, 0, 2, 1)"), std::string::npos) << petSql;
    EXPECT_EQ(Count(petSql, Guard), 13u) << petSql;
    EXPECT_TRUE(EndsWith(petSql, RevisionLast)) << petSql;

    std::string const teamSql = UpsertStatement(journal, writes[1]);
    EXPECT_NE(teamSql.find("INSERT INTO `coa_pet_team`"), std::string::npos) << teamSql;
    EXPECT_NE(teamSql.find("VALUES (42, 2, 501, 0, 0, 2)"), std::string::npos) << teamSql;
    EXPECT_EQ(Count(teamSql, Guard), 4u) << teamSql;
    EXPECT_TRUE(EndsWith(teamSql, RevisionLast)) << teamSql;

    std::string const accountSql = UpsertStatement(journal, writes[2]);
    EXPECT_NE(accountSql.find("INSERT INTO `coa_pet_account`"), std::string::npos) << accountSql;
    EXPECT_NE(accountSql.find("VALUES (42, 2, 3)"), std::string::npos) << accountSql;
    EXPECT_EQ(Count(accountSql, Guard), 2u) << accountSql;
    EXPECT_TRUE(EndsWith(accountSql, RevisionLast)) << accountSql;
}

TEST(CoAPetBattlesStore, UpsertOfAMissingPetIsEmpty)
{
    Journal journal(42, SqlCatalog(), {}, {}, 1, 0);
    EXPECT_EQ(UpsertStatement(journal, { RowKind::Pet, 42, 10, 1 }), "");
    EXPECT_EQ(UpsertStatement(journal, { RowKind::Team, 42, 4, 1 }), "");
}

TEST(CoAPetBattlesStore, LoginsOfOneAccountShareOneJournal)
{
    AccountRefs refs;
    EXPECT_TRUE(refs.Acquire(1, 100));
    EXPECT_FALSE(refs.Acquire(1, 200));
    EXPECT_FALSE(refs.Acquire(1, 100));
    EXPECT_FALSE(refs.Release(1, 100));
    EXPECT_FALSE(refs.Release(1, 300));
    EXPECT_TRUE(refs.Release(1, 200));
    EXPECT_FALSE(refs.Release(1, 200));
    EXPECT_TRUE(refs.Acquire(1, 200));
    EXPECT_TRUE(refs.Acquire(2, 100));
    EXPECT_EQ(refs.Online(1), 1u);
}

TEST(CoAPetBattlesStore, JournalOutlivesLogoutUntilItsWritesFinish)
{
    AccountRefs refs;
    EXPECT_TRUE(refs.Acquire(1, 100));
    refs.WriteStarted(1);
    refs.WriteStarted(1);
    EXPECT_EQ(refs.Pending(1), 2u);
    EXPECT_FALSE(refs.Release(1, 100));
    EXPECT_FALSE(refs.Acquire(1, 200));
    EXPECT_FALSE(refs.WriteFinished(1));
    EXPECT_FALSE(refs.Release(1, 200));
    EXPECT_TRUE(refs.WriteFinished(1));
    EXPECT_EQ(refs.Pending(1), 0u);
    EXPECT_TRUE(refs.Acquire(1, 100));
    refs.WriteStarted(1);
    EXPECT_FALSE(refs.WriteFinished(1));
    EXPECT_TRUE(refs.Release(1, 100));
    EXPECT_FALSE(refs.WriteFinished(1));
}

TEST(CoAPetBattlesStore, SpellsLearnedOnMapThreadsQueueForTheWorldThread)
{
    LearnQueue queue;
    std::vector<std::thread> threads;
    for (uint32_t thread = 0; thread < 4; ++thread)
        threads.emplace_back([&queue, thread]
        {
            for (uint32_t i = 0; i < 1000; ++i)
                queue.Push({ thread, uint64_t(thread) * 1000 + i, i });
        });
    for (std::thread& thread : threads)
        thread.join();
    std::vector<LearnedSpell> const drained = queue.Drain();
    EXPECT_EQ(drained.size(), 4000u);
    EXPECT_TRUE(queue.Drain().empty());
    EXPECT_EQ(drained.front().spell, 0u);
}

TEST(CoAPetBattlesStore, ReleaseTombstoneWinsAgainstDelayedUpserts)
{
    Journal journal(42, SqlCatalog(), {}, {}, 1, 0);
    std::string const sql = UpsertStatement(journal, { RowKind::Release, 42, 501, 9 });
    EXPECT_NE(sql.find("(`account`, `pet_id`, `species`, `source`, `revision`) VALUES (42, 501, 0, 3, 9)"),
        std::string::npos);
    EXPECT_EQ(Count(sql, Guard), 3u);
    EXPECT_TRUE(EndsWith(sql, RevisionLast));
}
