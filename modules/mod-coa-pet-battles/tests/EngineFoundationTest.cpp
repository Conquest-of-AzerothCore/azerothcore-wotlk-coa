#include "Engine/Event.h"
#include "Engine/LuaNumber.h"
#include "Engine/Rng.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <set>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

TEST(CoAPetBattlesEngine, LuaNumberMatchesLuaToString)
{
    EXPECT_EQ(LuaNumber(312.0), "312");
    EXPECT_EQ(LuaNumber(0.35), "0.35");
    EXPECT_EQ(LuaNumber(1.0 / 3.0), "0.33333333333333");
    EXPECT_EQ(LuaNumber(1e20), "1e+20");
    EXPECT_EQ(LuaNumber(-0.0), "-0");
    EXPECT_EQ(LuaNumber(7), "7");
    EXPECT_EQ(LuaNumber(233.75), "233.75");
}

TEST(CoAPetBattlesEngine, EventCanonicalSortsFields)
{
    Event event { "dmg", {} };
    event.fields["tidx"] = 2.0;
    event.fields["dmg"] = 312.0;
    event.fields["side"] = std::string("P");
    EXPECT_EQ(event.Canonical(), "k=dmg\tdmg=312\tside=P\ttidx=2");

    Event act { "act", {} };
    act.fields["dmg"] = true;
    act.fields["name"] = std::string("Lil' K.T.\tx");
    act.fields["tags.P"] = std::string("a");
    act.fields["tags.E"] = std::string("");
    act.fields["vis"] = 0.5;
    EXPECT_EQ(act.Canonical(), "k=act\tdmg=true\tname=Lil' K.T.\\tx\ttags.E=\ttags.P=a\tvis=0.5");
}

TEST(CoAPetBattlesEngine, ReplayRngReportsFirstDivergence)
{
    ReplayRng matching({ { 1, 100, 42 }, { 1, 2, 2 } });
    EXPECT_EQ(matching.Roll(1, 100), 42);
    EXPECT_EQ(matching.Roll(1, 2), 2);
    EXPECT_TRUE(matching.Exhausted());
    EXPECT_TRUE(matching.Divergence().empty());

    ReplayRng wrongRange({ { 1, 100, 42 } });
    wrongRange.Roll(1, 2);
    EXPECT_NE(wrongRange.Divergence().find("roll 0"), std::string::npos);
    EXPECT_NE(wrongRange.Divergence().find("1..100"), std::string::npos);
    EXPECT_NE(wrongRange.Divergence().find("1..2"), std::string::npos);

    ReplayRng tooMany({ { 1, 2, 1 } });
    tooMany.Roll(1, 2);
    tooMany.Roll(1, 3);
    EXPECT_NE(tooMany.Divergence().find("roll 1"), std::string::npos);

    SeededRng seeded(7);
    for (int i = 0; i < 100; ++i)
    {
        int32_t value = seeded.Roll(3, 5);
        EXPECT_GE(value, 3);
        EXPECT_LE(value, 5);
    }
}

TEST(CoAPetBattlesEngine, FixtureDataLoads)
{
    DataSet data = Fixtures::LoadData();
    std::vector<Fixtures::TraceBattle> battles = Fixtures::LoadTraces();
    ASSERT_FALSE(battles.empty());
    std::set<uint32_t> species;
    for (Fixtures::TraceBattle const& battle : battles)
        for (Fixtures::TracePet const& pet : battle.pets)
            species.insert(pet.species);
    EXPECT_EQ(data.species.size(), species.size());
    Report report = Validate(data, [](uint32_t) { return true; });
    EXPECT_TRUE(report.errors.empty()) << (report.errors.empty() ? "" : report.errors.front());
}
