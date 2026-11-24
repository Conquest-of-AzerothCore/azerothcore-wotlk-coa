#include "Store/AccountRefs.h"
#include "Store/JournalSql.h"
#include <gtest/gtest.h>
#include <string>

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
    pet.level = 4;
    pet.xp = 33;
    pet.picks = { 2, 1, 2 };
    pet.quality = 3;
    pet.display = 77;
    pet.health = 120;
    pet.healthAt = 5000;
    Journal journal(42, SqlCatalog(), { pet }, {}, 1, 0);
    ASSERT_TRUE(journal.SetPicks(10, { 2, 2, 2 }));
    ASSERT_EQ(journal.SetTeam(2, { 10, 0, 0 }), TeamResult::Saved);
    ASSERT_TRUE(journal.SetActiveTeam(2));
    std::vector<RowWrite> const writes = journal.TakeWrites();
    ASSERT_EQ(writes.size(), 3u);

    std::string const petSql = UpsertStatement(journal, writes[0]);
    EXPECT_NE(petSql.find("INSERT INTO `coa_pet_journal`"), std::string::npos) << petSql;
    EXPECT_NE(petSql.find("VALUES (42, 10, 4, 33, 2, 2, 2, 3, 77, 120, 5000, 1)"), std::string::npos) << petSql;
    EXPECT_EQ(Count(petSql, Guard), 10u) << petSql;
    EXPECT_TRUE(EndsWith(petSql, RevisionLast)) << petSql;

    std::string const teamSql = UpsertStatement(journal, writes[1]);
    EXPECT_NE(teamSql.find("INSERT INTO `coa_pet_team`"), std::string::npos) << teamSql;
    EXPECT_NE(teamSql.find("VALUES (42, 2, 10, 0, 0, 2)"), std::string::npos) << teamSql;
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
