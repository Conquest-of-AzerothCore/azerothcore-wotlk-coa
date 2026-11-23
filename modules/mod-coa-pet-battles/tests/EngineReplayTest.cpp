#include "Engine/LuaNumber.h"
#include "Engine/Pet.h"
#include "Engine/Round.h"
#include "FixtureReader.h"
#include <gtest/gtest.h>
#include <algorithm>
#include <sstream>

using namespace CoAPetBattles;
using namespace CoAPetBattles::Engine;

namespace
{
    Catalog const& ReplayCatalog()
    {
        static DataSet const data = Fixtures::LoadData();
        static Catalog const catalog(data, Settings());
        return catalog;
    }

    std::vector<std::string> StateRow(Battle const& battle, Side side, int32_t index)
    {
        Pet const& pet = battle.At(side, index);
        std::vector<std::string> auras;
        for (Aura const& aura : pet.auras)
            auras.push_back(LuaNumber(static_cast<double>(aura.id)) + ":" + LuaNumber(aura.left));
        std::sort(auras.begin(), auras.end());
        std::string auraText;
        for (std::string const& aura : auras)
            auraText += (auraText.empty() ? "" : ",") + aura;
        return { SideName(side), LuaNumber(index), LuaNumber(pet.hp), LuaNumber(pet.max), LuaNumber(pet.power),
            LuaNumber(Speed(nullptr, pet)), LuaNumber(pet.cd[0]) + "," + LuaNumber(pet.cd[1]) + "," +
            LuaNumber(pet.cd[2]), auraText, StatusString(ReplayCatalog(), pet) };
    }

    std::string Join(std::vector<std::string> const& fields)
    {
        std::string text;
        for (std::string const& field : fields)
            text += (text.empty() ? "" : "\t") + field;
        return text;
    }

    std::string FirstDifference(std::vector<std::string> const& expected, std::vector<std::string> const& actual)
    {
        for (size_t i = 0; i < std::max(expected.size(), actual.size()); ++i)
        {
            std::string const want = i < expected.size() ? expected[i] : "<none>";
            std::string const got = i < actual.size() ? actual[i] : "<none>";
            if (want != got)
                return "line " + std::to_string(i) + "\n expected: " + want + "\n actual:   " + got;
        }
        return "";
    }

    struct ReplayOutcome
    {
        std::string failure;
        size_t rounds = 0;
        size_t invalidCommands = 0;
    };

    ReplayOutcome Replay(Fixtures::TraceBattle const& trace)
    {
        ReplayOutcome outcome;
        ReplayRng rng(trace.rolls);
        std::vector<Pet> mine;
        std::vector<Pet> theirs;
        for (Fixtures::TracePet const& recorded : trace.pets)
        {
            double const quality = RollQuality(ReplayCatalog(), rng);
            Pet pet = NewPet(ReplayCatalog(), recorded.species, recorded.level, recorded.picks, rng, quality,
                recorded.hp);
            (recorded.side == "P" ? mine : theirs).push_back(std::move(pet));
        }
        Battle battle(ReplayCatalog(), std::move(mine), std::move(theirs), rng);
        for (size_t r = 0; r < trace.rounds.size(); ++r)
        {
            Fixtures::TraceRound const& round = trace.rounds[r];
            std::string const where = "battle " + std::to_string(trace.id) + " round " + std::to_string(r + 1);
            Pet const& active = battle.Current(Side::P);
            char const kind = round.commandP.empty() ? ' ' : round.commandP[0];
            if ((kind == 'T' && !CanTrap(battle)) ||
                (kind == 'A' && !active.channel && !Ready(active, std::stoi(round.commandP.substr(1)))))
                ++outcome.invalidCommands;
            std::string const enemy = AI(battle, Side::E);
            if (enemy != round.commandE)
            {
                outcome.failure = where + ": AI chose " + enemy + ", upstream " + round.commandE;
                return outcome;
            }
            RoundResult const result = Round(battle, round.commandP, enemy);
            std::vector<std::string> events;
            for (Event const& event : result.events)
                events.push_back(event.Canonical());
            if (std::string diff = FirstDifference(round.events, events); !diff.empty())
            {
                outcome.failure = where + " events: " + diff;
                return outcome;
            }
            if (result.status != round.status)
            {
                outcome.failure = where + ": status " + result.status + ", upstream " + round.status;
                return outcome;
            }
            std::vector<std::string> expectedStates;
            std::vector<std::string> actualStates;
            for (std::vector<std::string> const& state : round.states)
            {
                expectedStates.push_back(Join(state));
                Side const side = state[0] == "P" ? Side::P : Side::E;
                actualStates.push_back(Join(StateRow(battle, side, std::stoi(state[1]))));
            }
            if (std::string diff = FirstDifference(expectedStates, actualStates); !diff.empty())
            {
                outcome.failure = where + " state: " + diff;
                return outcome;
            }
            if (!rng.Divergence().empty())
            {
                outcome.failure = where + ": " + rng.Divergence();
                return outcome;
            }
            ++outcome.rounds;
        }
        if (!rng.Exhausted())
            outcome.failure = "battle " + std::to_string(trace.id) + ": " +
                std::to_string(trace.rolls.size() - rng.Used()) + " recorded rolls never used";
        else if (!UnknownEffects(battle).empty())
            outcome.failure = "battle " + std::to_string(trace.id) + ": unknown effect handler fired";
        return outcome;
    }
}

TEST(CoAPetBattlesEngine, EveryRecordedBattleReplays)
{
    std::vector<Fixtures::TraceBattle> const battles = Fixtures::LoadTraces();
    size_t rounds = 0;
    size_t failed = 0;
    std::string firstFailure;
    for (Fixtures::TraceBattle const& trace : battles)
    {
        ReplayOutcome const outcome = Replay(trace);
        rounds += outcome.rounds;
        if (!outcome.failure.empty())
        {
            ++failed;
            if (firstFailure.empty())
                firstFailure = outcome.failure;
        }
    }
    EXPECT_EQ(failed, 0u) << failed << " of " << battles.size() << " battles differ; first: " << firstFailure;
    EXPECT_GT(rounds, 0u);
}

TEST(CoAPetBattlesEngine, InvalidCommandsMatchUpstream)
{
    size_t invalid = 0;
    for (Fixtures::TraceBattle const& trace : Fixtures::LoadTraces())
    {
        ReplayOutcome const outcome = Replay(trace);
        ASSERT_TRUE(outcome.failure.empty()) << outcome.failure;
        invalid += outcome.invalidCommands;
    }
    EXPECT_GT(invalid, 0u);
}
