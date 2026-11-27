#include "FixtureReader.h"
#include "Store/Journal.h"
#include <gtest/gtest.h>

using namespace CoAPetBattles;

namespace
{
    std::shared_ptr<Engine::Catalog const> const& FeedingCatalog()
    {
        static DataSet const data = Fixtures::LoadData();
        static std::shared_ptr<Engine::Catalog const> const catalog =
            std::make_shared<Engine::Catalog const>(data, Settings());
        return catalog;
    }

    struct Fed
    {
        Fed()
        {
            species = FeedingCatalog()->SpeciesIds().front();
            Store::OwnedPet pet;
            pet.species = species;
            pet.id = species;
            pet.level = 5;
            journal = std::make_unique<Store::Journal>(1, *FeedingCatalog(), std::vector<Store::OwnedPet> { pet },
                std::array<Store::Team, Store::TeamCount> {}, 1, 0);
            max = journal->MaxHealth(*journal->Pet(species));
            journal->SetHealth(species, max / 10, Start);
        }

        uint32_t Health(uint32_t at) const { return journal->CurrentHealth(*journal->Pet(species), at); }

        static constexpr uint32_t Start = 1700000000;
        uint32_t species = 0;
        uint32_t max = 0;
        std::unique_ptr<Store::Journal> journal;
    };
}

TEST(CoAPetBattlesFeeding, FedHealGrowsInSteps)
{
    Fed fed;
    uint32_t const step = fed.max * 10 / 100;
    ASSERT_EQ(fed.journal->Feed(fed.species, 5, Fed::Start), Store::FeedResult::Fed);
    EXPECT_EQ(fed.Health(Fed::Start + 1), fed.max / 10);
    EXPECT_EQ(fed.Health(Fed::Start + 2), fed.max / 10 + step);
    EXPECT_EQ(fed.Health(Fed::Start + 4), fed.max / 10 + 2 * step);
    EXPECT_EQ(fed.Health(Fed::Start + 18), std::min(fed.max, fed.max / 10 + 9 * step + fed.max / 100));
    EXPECT_EQ(fed.Health(Fed::Start + 600), fed.max);
}

TEST(CoAPetBattlesFeeding, FedHealEndsOnHealthChange)
{
    Fed fed;
    ASSERT_EQ(fed.journal->Feed(fed.species, 5, Fed::Start), Store::FeedResult::Fed);
    fed.journal->SetHealth(fed.species, fed.max / 10, Fed::Start + 4);
    EXPECT_EQ(fed.Health(Fed::Start + 8), fed.max / 10);
}

TEST(CoAPetBattlesFeeding, TooWeakFoodIsRefused)
{
    Fed fed;
    EXPECT_EQ(fed.journal->Feed(fed.species, 4, Fed::Start), Store::FeedResult::TooWeak);
    EXPECT_EQ(fed.Health(Fed::Start + 8), fed.max / 10);
}

TEST(CoAPetBattlesFeeding, FullHealthIsRefused)
{
    Fed fed;
    fed.journal->SetHealth(fed.species, fed.max, Fed::Start);
    EXPECT_EQ(fed.journal->Feed(fed.species, 25, Fed::Start), Store::FeedResult::FullHealth);
    uint32_t const other = FeedingCatalog()->SpeciesIds()[1];
    EXPECT_EQ(fed.journal->Feed(other, 25, Fed::Start), Store::FeedResult::NotOwned);
}
