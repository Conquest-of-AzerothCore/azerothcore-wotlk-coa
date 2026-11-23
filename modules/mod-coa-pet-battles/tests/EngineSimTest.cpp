#include "Engine/Sim.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <algorithm>
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
}
