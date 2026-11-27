#include "Engine/Describe.h"
#include "Engine/LuaNumber.h"
#include "Engine/PetFactory.h"
#include "Engine/Rules.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <iterator>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

namespace
{
    DataSet const& FixtureData()
    {
        static DataSet const data = Fixtures::LoadData();
        return data;
    }

    Catalog const& FixtureCatalog()
    {
        static Catalog const catalog(FixtureData(), Settings());
        return catalog;
    }

    std::vector<Fixtures::TraceBattle> const& Battles()
    {
        static std::vector<Fixtures::TraceBattle> const battles = Fixtures::LoadTraces();
        return battles;
    }

    std::string AbilityIds(Pet const& pet)
    {
        std::string ids;
        for (size_t slot = 0; slot < 3; ++slot)
            ids += (slot ? "," : "") + (pet.abil[slot] ? std::to_string(pet.abil[slot]->id) : std::string("nil"));
        return ids;
    }
}

TEST(CoAPetBattlesEngine, RulesMatchUpstream)
{
    Stats const stats = PetStats(0, 0, 0, 25, 3, 25);
    EXPECT_EQ(stats.health, 1400);
    EXPECT_EQ(stats.power, 260);
    EXPECT_EQ(stats.speed, 260);
    EXPECT_EQ(Matchup("Beast", "Critter"), 1.5);
    EXPECT_EQ(Matchup("Beast", "Flying"), 2.0 / 3.0);
    EXPECT_EQ(Matchup("Beast", "Beast"), 1.0);
    EXPECT_EQ(Heal(0, 0), 1);
    EXPECT_EQ(Damage(20, 260, "Beast", "Critter", 0, 0), 420);
    EXPECT_FALSE(FamilyAt(0).has_value());
    EXPECT_EQ(*FamilyAt(8), "Beast");
}

TEST(CoAPetBattlesEngine, WildBreedRollAndRetailStatsAgree)
{
    DataSet data = FixtureData();
    uint32_t const species = data.species.begin()->first;
    uint32_t const unmapped = std::next(data.species.begin())->first;
    data.breeds[species] = { { 3, { 1700, 1500, 1900 } }, { 5, { 1600, 1400, 2200 } } };
    Catalog const catalog(data, Settings());
    ReplayRng rng({ { 0, 1, 1 } });
    EXPECT_EQ(RollBreed(catalog, unmapped, rng), 0u);
    uint8_t const breed = RollBreed(catalog, species, rng);
    EXPECT_EQ(breed, 5u);
    Pet const pet = NewPet(catalog, species, 25, std::array<int32_t, 3> { 1, 1, 1 }, rng, 3, std::nullopt, breed);
    EXPECT_EQ(pet.breed, 5u);
    EXPECT_EQ(pet.max, 1400.0);
    EXPECT_EQ(pet.power, 227.0);
    EXPECT_EQ(pet.speed, 357.0);
    EXPECT_TRUE(rng.Exhausted());
    EXPECT_TRUE(rng.Divergence().empty());
}

TEST(CoAPetBattlesEngine, SharedBreedsPreserveKitsAndDeferToRetailProfiles)
{
    DataSet data = FixtureData();
    uint32_t const fallback = data.species.begin()->first;
    uint32_t const retail = std::next(data.species.begin())->first;
    data.defaultBreeds = { { BalancedBreed, {} }, { 5, { -50, -50, 150 } } };
    data.breeds[retail] = { { 7, { 1780, 1680, 1700 } } };
    Catalog const catalog(data, Settings());
    SpeciesDef const* def = catalog.Species(fallback);
    ASSERT_NE(def, nullptr);
    Stats const old = StatsForPet(*def, 20, 3, 25, 0);
    Stats const balanced = StatsForPet(*def, 20, 3, 25, BalancedBreed);
    EXPECT_EQ(balanced.health, old.health);
    EXPECT_EQ(balanced.power, old.power);
    EXPECT_EQ(balanced.speed, old.speed);
    ReplayRng rng({ { 0, 1, 1 } });
    EXPECT_EQ(RollBreed(catalog, retail, rng), 7u);
    uint8_t const breed = RollBreed(catalog, fallback, rng);
    EXPECT_EQ(breed, 5u);
    Stats const fast = StatsForPet(*def, 20, 3, 25, breed);
    EXPECT_EQ(fast.health - old.health, -65);
    EXPECT_NEAR(fast.power - old.power, -13, 1e-9);
    EXPECT_NEAR(fast.speed - old.speed, 39, 1e-9);
    EXPECT_TRUE(rng.Exhausted());
    EXPECT_TRUE(rng.Divergence().empty());
}

TEST(CoAPetBattlesEngine, PetsBuildLikeUpstream)
{
    size_t built = 0;
    for (Fixtures::TraceBattle const& battle : Battles())
    {
        ReplayRng rng(battle.rolls);
        for (Fixtures::TracePet const& expected : battle.pets)
        {
            double const quality = RollQuality(FixtureCatalog(), rng);
            ASSERT_EQ(quality, expected.quality) << "battle " << battle.id;
            Pet const pet = NewPet(FixtureCatalog(), expected.species, expected.level, expected.picks, rng, quality,
                expected.hp);
            ASSERT_TRUE(rng.Divergence().empty()) << "battle " << battle.id << ": " << rng.Divergence();
            ASSERT_EQ(expected.built.size(), 4u);
            EXPECT_EQ(LuaNumber(pet.max), expected.built[0]) << "battle " << battle.id;
            EXPECT_EQ(LuaNumber(pet.power), expected.built[1]) << "battle " << battle.id;
            EXPECT_EQ(LuaNumber(pet.speed), expected.built[2]) << "battle " << battle.id;
            EXPECT_EQ(AbilityIds(pet), expected.built[3]) << "battle " << battle.id;
            ++built;
        }
    }
    EXPECT_GT(built, 0u);
}

TEST(CoAPetBattlesEngine, DescribeMatchesUpstreamForEveryKitAbility)
{
    size_t compared = 0;
    size_t kitCompared = 0;
    size_t excluded = 0;
    for (Fixtures::TraceBattle const& battle : Battles())
    {
        ReplayRng rng(battle.rolls);
        std::vector<Pet> pets;
        for (Fixtures::TracePet const& expected : battle.pets)
        {
            double const quality = RollQuality(FixtureCatalog(), rng);
            pets.push_back(NewPet(FixtureCatalog(), expected.species, expected.level, expected.picks, rng, quality,
                expected.hp));
        }
        for (Fixtures::TraceTip const& tip : battle.tips)
        {
            if (tip.excluded)
            {
                ++excluded;
                continue;
            }
            size_t offset = 0;
            for (size_t i = 0; i < battle.pets.size(); ++i)
                if (battle.pets[i].side == tip.side && battle.pets[i].index == tip.index)
                    offset = i;
            PetAbility const* ability = pets[offset].Ability(tip.slot);
            ASSERT_NE(ability, nullptr) << "battle " << battle.id;
            EXPECT_EQ(ability->tip, tip.text) << "battle " << battle.id << " " << tip.side << tip.index << " slot "
                << tip.slot;
            ++compared;
        }
        for (Fixtures::TraceKitTip const& tip : battle.kitTips)
        {
            if (tip.excluded)
            {
                ++excluded;
                continue;
            }
            size_t offset = 0;
            for (size_t i = 0; i < battle.pets.size(); ++i)
                if (battle.pets[i].side == tip.side && battle.pets[i].index == tip.index)
                    offset = i;
            bool found = false;
            for (KitOption const& option : Engine::Kit(FixtureCatalog(), battle.pets[offset].species))
                if (option.slot == tip.slot && option.option == tip.option)
                {
                    found = true;
                    EXPECT_EQ(Describe(FixtureCatalog(), { option.ability.text, &option.ability.turns,
                        option.ability.family, std::nullopt }, pets[offset].power), tip.text)
                        << "battle " << battle.id << " species " << battle.pets[offset].species << " slot "
                        << tip.slot << " option " << tip.option;
                }
            EXPECT_TRUE(found) << "battle " << battle.id << " slot " << tip.slot << " option " << tip.option;
            ++kitCompared;
        }
    }
    EXPECT_GT(compared, 0u);
    EXPECT_GT(kitCompared, compared);
    EXPECT_EQ(excluded, 0u);
}

TEST(CoAPetBattlesEngine, DescribeSurvivesMissingReferences)
{
    std::vector<Turn> const none;
    auto describe = [&none](std::string const& text)
    {
        return Describe(FixtureCatalog(), { text, &none, 7, std::nullopt }, 100);
    };
    EXPECT_EQ(describe("[abs(abilityStateMod(99999,99999))] and [Points(5,5)] [Foo(1)] [] [2+2*3] [-5*1.5] "
        "|cffffffffHit|r 1 |4round:rounds; 3 |4round:rounds"), "0 and 0 ? ? 8 -7 Hit 1 round 3 rounds");
    EXPECT_EQ(describe("50%% Hit Chance   [StandardAccuracy(1,1)] |cffffffffHit Chance|r  Bites [School()] "
        "(Current: [x])"), "50% hit chance. 100% hit chance. Bites Beast");
    EXPECT_EQ(describe("[1/0] [0/0] [5--3] [.5] [1.2.3] [(2)]"), "inf -nan 5 1 1.2.3 2");
}

TEST(CoAPetBattlesEngine, KitIsSortedLikeUpstream)
{
    for (uint32_t species : FixtureCatalog().SpeciesIds())
    {
        std::vector<KitOption> const kit = Engine::Kit(FixtureCatalog(), species);
        for (size_t i = 1; i < kit.size(); ++i)
        {
            ASSERT_LE(kit[i - 1].slot, kit[i].slot) << species;
            if (kit[i - 1].slot == kit[i].slot)
            {
                EXPECT_LT(kit[i - 1].option, kit[i].option) << species;
                EXPECT_LE(kit[i - 1].unlock, kit[i].unlock) << species;
            }
        }
        for (KitOption const& entry : kit)
        {
            EXPECT_GE(entry.slot, 1) << species;
            EXPECT_LE(entry.slot, 3) << species;
        }
    }
}
