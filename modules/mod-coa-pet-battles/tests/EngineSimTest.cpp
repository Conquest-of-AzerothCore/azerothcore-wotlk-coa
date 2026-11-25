#include "Engine/Battle.h"
#include "Engine/PetFactory.h"
#include "Engine/Sim.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <cctype>
#include <map>
#include <random>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

namespace
{
    Catalog const& SimCatalog()
    {
        static DataSet const data = Fixtures::LoadData();
        static Catalog const catalog(data, Settings());
        return catalog;
    }

    std::pair<uint32_t, uint32_t> TwoSpecies()
    {
        std::vector<uint32_t> const species = SimCatalog().SpeciesIds();
        return { species.front(), species.back() };
    }

    bool EndsBattle(std::string const& line)
    {
        return line == "Draw after 50 rounds." || (line.size() > 6 && line.substr(line.size() - 6) == " wins.");
    }
}

TEST(CoAPetBattlesSim, SimIsDeterministicForASeed)
{
    auto const [a, b] = TwoSpecies();
    SimResult const first = RunSim(SimCatalog(), a, b, 25, 4127);
    SimResult const second = RunSim(SimCatalog(), a, b, 25, 4127);
    ASSERT_TRUE(first.error.empty()) << first.error;
    EXPECT_EQ(first.lines, second.lines);
    EXPECT_GT(first.lines.size(), 2u);
}

TEST(CoAPetBattlesSim, SimHeaderNamesSeedAndLevel)
{
    auto const [a, b] = TwoSpecies();
    SimResult const result = RunSim(SimCatalog(), a, b, 12, 99);
    ASSERT_FALSE(result.lines.empty());
    std::string const expected = "[Pet sim] " + SimCatalog().Species(a)->name + " (12 rare) vs " +
        SimCatalog().Species(b)->name + " (12 rare), seed 99";
    EXPECT_EQ(result.lines.front(), expected);
}

TEST(CoAPetBattlesSim, SimEndsWithinRoundLimit)
{
    std::vector<uint32_t> const species = SimCatalog().SpeciesIds();
    std::mt19937 pick(1);
    std::uniform_int_distribution<size_t> index(0, species.size() - 1);
    for (int i = 0; i < 200; ++i)
    {
        uint32_t const a = species[index(pick)];
        uint32_t const b = species[index(pick)];
        SimResult const result = RunSim(SimCatalog(), a, b, 25, 1);
        ASSERT_TRUE(result.error.empty()) << a << " vs " << b << ": " << result.error;
        ASSERT_FALSE(result.lines.empty());
        EXPECT_TRUE(EndsBattle(result.lines.back())) << a << " vs " << b << ": " << result.lines.back();
        for (std::string const& line : result.lines)
            if (line.size() > 1 && line[0] == 'R' && line[1] >= '0' && line[1] <= '9')
            {
                size_t const space = line.find(' ');
                ASSERT_NE(space, std::string::npos);
                EXPECT_LE(std::stoi(line.substr(1, space - 1)), 50) << line;
            }
    }
}

TEST(CoAPetBattlesSim, SimArgumentsAreValidated)
{
    auto const [a, b] = TwoSpecies();
    SimResult const unknown = RunSim(SimCatalog(), 4000000000u, b, 25, 1);
    EXPECT_EQ(unknown.error, "unknown pet species 4000000000");
    EXPECT_TRUE(unknown.lines.empty());
    SimResult const low = RunSim(SimCatalog(), a, b, 0, 1);
    EXPECT_EQ(low.error, "level must be 1-25");
    EXPECT_TRUE(low.lines.empty());
    EXPECT_EQ(RunSim(SimCatalog(), a, b, 26, 1).error, "level must be 1-25");

    DataSet data = Fixtures::LoadData();
    uint32_t const bare = data.species.begin()->first;
    data.presentations.erase(std::remove_if(data.presentations.begin(), data.presentations.end(),
        [bare](Presentation const& row) { return row.species == bare; }), data.presentations.end());
    Catalog const withoutKit(data, Settings());
    SimResult const noKit = RunSim(withoutKit, bare, b, 25, 1);
    EXPECT_EQ(noKit.error, "pet species " + std::to_string(bare) + " has no abilities");
    EXPECT_TRUE(noKit.lines.empty());

    DataSet kitless = Fixtures::LoadData();
    kitless.kits.erase(kitless.species.at(bare).kit);
    Catalog const missingKit(kitless, Settings());
    EXPECT_EQ(RunSim(missingKit, bare, b, 25, 1).error, "pet species " + std::to_string(bare) + " has no kit");
    EXPECT_EQ(RunSim(missingKit, 4000000000u, b, 25, 1).error, "unknown pet species 4000000000");
}

TEST(CoAPetBattlesSim, SimNamesPermanentAurasAndWallCharges)
{
    auto const [a, b] = TwoSpecies();
    SeededRng rng(1);
    Pet mine = NewPet(SimCatalog(), a, 25, std::nullopt, rng, 4, std::nullopt);
    Pet theirs = NewPet(SimCatalog(), b, 25, std::nullopt, rng, 4, std::nullopt);
    Aura perm;
    perm.id = 900;
    perm.left = 99;
    perm.perm = true;
    mine.auras.push_back(perm);
    Battle battle(SimCatalog(), { mine }, { theirs }, rng);
    battle.wall = Wall { 326, 2, Side::E };
    auto buff = [](std::string const& side, std::string const& what, double turns)
    {
        Event event { "buff", {} };
        event.fields["side"] = side;
        event.fields["idx"] = 1.0;
        event.fields["what"] = what;
        event.fields["turns"] = turns;
        return event;
    };
    auto lower = [](std::string text)
    {
        std::transform(text.begin(), text.end(), text.begin(), [](unsigned char c) { return std::tolower(c); });
        return text;
    };
    std::string const permName = lower(AuraName(SimCatalog(), 900));
    std::string const wallName = lower(AuraName(SimCatalog(), 326));
    ASSERT_NE(permName, wallName);
    std::map<Side, std::string> used;
    EXPECT_EQ(SimLine(battle, buff("P", permName, 99), used),
        battle.Current(Side::P).name + ": " + permName + " (permanent)");
    EXPECT_EQ(SimLine(battle, buff("E", wallName, 2), used),
        battle.Current(Side::E).name + ": " + wallName + " (2 charges)");
    EXPECT_EQ(SimLine(battle, buff("E", "howl", 3), used), battle.Current(Side::E).name + ": howl (3 rounds)");
    EXPECT_EQ(SimLine(battle, buff("P", wallName, 2), used),
        battle.Current(Side::P).name + ": " + wallName + " (2 rounds)");
}
